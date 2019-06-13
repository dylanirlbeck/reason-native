/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */;
module Reporter = Reporter;
module Time = Time;
module Mock = Mock;

/* maintained for backwards compatibility */
module Test = Test;
include (module type of Test);

/* maintained for backwards compatibility */
module Describe = Describe;

include (module type of Describe);

module RunConfig: {
  type reporter =
    | Default
    | JUnit(string)
    | Custom(Reporter.t);

  type t;

  let initialize: unit => t;
  let onTestFrameworkFailure: (unit => unit, t) => t;
  let updateSnapshots: (bool, t) => t;
  let withReporters: (list(reporter), t) => t;
  let internal_do_not_use_get_time: (unit => Time.t, t) => t;
  let ciMode: (bool, t) => t;
};

module MatcherUtils: {
  type matcherHintOptions = {comment: option(string)};

  type t = {
    matcherHint:
      (
        ~matcherName: string,
        ~expectType: string,
        ~isNot: bool=?,
        ~received: string=?,
        ~expected: string=?,
        ~options: matcherHintOptions=?,
        unit
      ) =>
      string,
    formatReceived: string => string,
    formatExpected: string => string,
    prepareDiff: (string, string) => string,
    indent: string => string,
  };
};

module MatcherTypes: {
  type thunk('a) = unit => 'a;
  type matcher('a, 'b) =
    (MatcherUtils.t, thunk('a), thunk('b)) => (thunk(string), bool);
  type matcherConfig('a, 'b) =
    (MatcherUtils.t, unit => 'a, unit => 'b) => (unit => string, bool);
  type matcherResult('a, 'b) = (unit => 'a, unit => 'b) => unit;
  type createMatcher('a, 'b) =
    matcherConfig('a, 'b) => matcherResult('a, 'b);
  type extendUtils = {createMatcher: 'a 'b. createMatcher('a, 'b)};
  type matchersExtensionFn('ext) = extendUtils => 'ext;
};

type testLibrary;
type combineResult = {
  run: RunConfig.t => unit,
  cli: unit => unit,
  testLibrary,
};

let combine: list(testLibrary) => combineResult;

open TestLifecycle;
module type TestFramework = {
  module Mock: Mock.Sig;
  include (module type of Describe);
  include (module type of Test);

  let describe: Describe.describeFn(unit, unit);
  let describeSkip: Describe.describeFn(unit, unit);
  let describeOnly: Describe.describeFn(unit, unit);
  let run: RunConfig.t => unit;
  let cli: unit => unit;
  let toLibrary: unit => testLibrary;
  let testLifecycle: TestLifecycle.defaultLifecycle;
  let beforeAll:
    (
      unit => 'all,
      TestLifecycle.t(
        beforeAllNotCalled,
        afterAllNotCalled,
        beforeEachNotCalled,
        afterEachNotCalled,
        'oldAll,
        'each,
      )
    ) =>
    TestLifecycle.t(
      beforeAllCalled,
      afterAllNotCalled,
      beforeEachNotCalled,
      afterEachNotCalled,
      'all,
      'all,
    );

  let afterAll:
    (
      'all => unit,
      TestLifecycle.t(
        'beforeAllCalled,
        afterAllNotCalled,
        'beforeEachCalled,
        'afterEachCalled,
        'all,
        'each,
      )
    ) =>
    TestLifecycle.t(
      'beforeAllCalled,
      afterAllCalled,
      'beforeEachCalled,
      'afterEachCalled,
      'all,
      'each,
    );

  let beforeEach:
    (
      'all => 'each,
      TestLifecycle.t(
        'beforeAllCalled,
        'afterAllCalled,
        beforeEachNotCalled,
        afterEachNotCalled,
        'all,
        'oldEach,
      )
    ) =>
    TestLifecycle.t(
      'beforeAllCalled,
      'afterAllCalled,
      beforeEachCalled,
      afterEachNotCalled,
      'all,
      'each,
    );

  let afterEach:
    (
      'each => unit,
      TestLifecycle.t(
        'beforeAllCalled,
        'afterAllCalled,
        'beforeEachCalled,
        afterEachNotCalled,
        'all,
        'each,
      )
    ) =>
    TestLifecycle.t(
      'beforeAllCalled,
      'afterAllCalled,
      'beforeEachCalled,
      afterEachCalled,
      'all,
      'each,
    );

  type describeConfig('ext, 'env);
  let withLifecycle:
    (
      TestLifecycle.defaultLifecycle => TestLifecycle.t(_, _, _, _, _, 'env),
      describeConfig('ext, unit)
    ) =>
    describeConfig('ext, 'env);
  let withCustomMatchers:
    (MatcherTypes.matchersExtensionFn('ext), describeConfig(unit, 'env)) =>
    describeConfig('ext, 'env);

  let describeConfig: describeConfig(unit, unit);
  let extendDescribe:
    describeConfig('ext, 'env) => extensionResult('ext, 'env);
};

type requiredConfiguration = TestFrameworkConfig.requiredConfiguration;

module TestFrameworkConfig: {
  type t;
  let initialize: requiredConfiguration => t;
  let withMaxNumberOfMockCalls: (int, t) => t;
};

module type FrameworkConfig = {let config: TestFrameworkConfig.t;};

module Make: (FrameworkConfig) => TestFramework;
