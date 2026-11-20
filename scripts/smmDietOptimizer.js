// Copyright 2026 Sacha Mallais. Repository license: CC BY 4.0.
// Independently authored bounded resource planner; no external optimizer code.

function finite(value, label) {
  if (typeof value !== "number" || !Number.isFinite(value))
    throw new Error("Invalid " + label);
  return value;
}

function integer(value, label) {
  finite(value, label);
  if (!Number.isInteger(value) || value < 0)
    throw new Error("Invalid " + label);
  return value;
}

// Each group supplies alternatives for the same item. Its limit applies across
// all alternatives. Resources can include organs and shared daily allowances.
// Negative resource use (cleaning) is supported only for finite groups.
function solve(problem) {
  var capacity = problem.capacity.map(function (n) {
    return integer(n, "capacity");
  });
  var width = capacity.length;
  var maxStates = integer(
    problem.maxStates === undefined ? 250000 : problem.maxStates,
    "state limit",
  );
  var maxTransitions = integer(
    problem.maxTransitions === undefined ? 10000000 : problem.maxTransitions,
    "transition limit",
  );
  var transitions = 0;
  var groups = problem.groups.map(function (group, groupIndex) {
    var bounded = group.limit !== undefined;
    var limit = bounded ? integer(group.limit, "item limit") : null;
    var choices = group.options.map(function (option, choiceIndex) {
      if (option.use.length !== width)
        throw new Error("Resource dimension mismatch");
      var use = option.use.map(function (n) {
        finite(n, "resource use");
        if (!Number.isInteger(n)) throw new Error("Non-integer resource use");
        if (n < 0 && !bounded)
          throw new Error("Cleaning requires an item limit");
        return n;
      });
      return {
        use: use,
        value: finite(option.value, "value"),
        option: option,
        group: groupIndex,
        choice: choiceIndex,
      };
    });
    return { limit: limit, options: choices, index: groupIndex };
  });

  var relief = capacity.map(function () {
    return 0;
  });
  groups.forEach(function (group) {
    if (group.limit === null) return;
    for (var d = 0; d < width; d++) {
      var freed = 0;
      group.options.forEach(function (option) {
        freed = Math.max(freed, -option.use[d]);
      });
      relief[d] += freed * group.limit;
    }
  });
  var envelope = capacity.map(function (n, i) {
    return n + relief[i];
  });
  groups.forEach(function (group) {
    if (group.limit !== null) return;
    var least = Infinity,
      touched = capacity.map(function () {
        return false;
      });
    group.options.forEach(function (option) {
      var total = option.use.reduce(function (sum, n, i) {
        if (n > 0) touched[i] = true;
        return sum + n;
      }, 0);
      if (!total) throw new Error("Zero-resource items require an item limit");
      least = Math.min(least, total);
    });
    group.limit = Math.floor(
      envelope.reduce(function (sum, n, i) {
        return sum + (touched[i] ? n : 0);
      }, 0) / least,
    );
  });

  // A finite option can be discarded only if an unlimited, no-more-demanding
  // option can always replace it. Preserve equal choices for deterministic ties.
  var unlimited = groups
    .filter(function (g) {
      return problem.groups[g.index].limit === undefined;
    })
    .reduce(function (a, g) {
      return a.concat(g.options);
    }, []);
  groups.forEach(function (group) {
    group.options = group.options.filter(function (option) {
      return !unlimited.some(function (other) {
        return (
          other !== option &&
          other.value > option.value &&
          other.use.every(function (n, i) {
            return n <= option.use[i];
          })
        );
      });
    });
  });
  groups = groups.filter(function (g) {
    return g.limit > 0 && g.options.length;
  });
  // Buying space first makes the subsequent sparse frontier much smaller.
  groups.sort(function (a, b) {
    var negative = function (g) {
      return g.options.some(function (o) {
        return o.use.some(function (n) {
          return n < 0;
        });
      });
    };
    return Number(negative(b)) - Number(negative(a)) || a.index - b.index;
  });

  function key(use) {
    return use.join(",");
  }
  function retain(map, state) {
    var k = key(state.use),
      previous = map.get(k);
    if (!previous || state.value > previous.value + 1e-8) map.set(k, state);
    if (map.size > maxStates)
      throw new Error(
        "Diet search state limit reached; no partial plan is executable",
      );
  }
  var initial = {
    use: capacity.map(function () {
      return 0;
    }),
    value: 0,
    previous: null,
    choice: null,
  };
  var frontier = new Map([[key(initial.use), initial]]);
  var futureRelief = relief.slice();
  groups.forEach(function (group) {
    var groupRelief = [];
    for (var d = 0; d < width; d++) {
      var freed = 0;
      group.options.forEach(function (o) {
        freed = Math.max(freed, -o.use[d]);
      });
      futureRelief[d] -= freed * group.limit;
      groupRelief[d] = freed;
    }
    var output = new Map(frontier);
    var layer = frontier;
    for (var quantity = 1; quantity <= group.limit && layer.size; quantity++) {
      var next = new Map();
      layer.forEach(function (state) {
        group.options.forEach(function (option) {
          transitions++;
          if (transitions > maxTransitions)
            throw new Error(
              "Diet search transition limit reached; no partial plan is executable",
            );
          var use = state.use.map(function (n, i) {
            return n + option.use[i];
          });
          if (
            use.some(function (n, i) {
              return (
                n >
                  capacity[i] +
                    futureRelief[i] +
                    groupRelief[i] * (group.limit - quantity) || n < -relief[i]
              );
            })
          )
            return;
          var candidate = {
            use: use,
            value: state.value + option.value,
            previous: state,
            choice: option,
          };
          retain(next, candidate);
          retain(output, candidate);
        });
      });
      layer = next;
    }
    // No later choice can rescue a state beyond this remaining relief bound.
    frontier = new Map();
    output.forEach(function (state) {
      if (
        state.use.every(function (n, i) {
          return n <= capacity[i] + futureRelief[i];
        })
      )
        retain(frontier, state);
    });
  });
  var best = initial;
  frontier.forEach(function (state) {
    if (
      state.use.some(function (n, i) {
        return n > capacity[i];
      })
    )
      return;
    var filled = state.use.slice(0, 3).reduce(function (a, n) {
      return a + Math.max(0, n);
    }, 0);
    var bestFilled = best.use.slice(0, 3).reduce(function (a, n) {
      return a + Math.max(0, n);
    }, 0);
    if (
      state.value > best.value + 1e-8 ||
      (Math.abs(state.value - best.value) <= 1e-8 && filled > bestFilled)
    )
      best = state;
  });
  var selections = new Map();
  for (var cursor = best; cursor.choice; cursor = cursor.previous) {
    var id = cursor.choice.group + ":" + cursor.choice.choice;
    if (!selections.has(id))
      selections.set(id, { option: cursor.choice.option, count: 0 });
    selections.get(id).count++;
  }
  return {
    value: best.value,
    use: best.use.slice(),
    selections: Array.from(selections.values()),
    complete: true,
    transitions: transitions,
  };
}

module.exports = { solve: solve };
