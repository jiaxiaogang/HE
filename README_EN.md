# he4o System

English | [简体中文](README.md)

Since childhood I have loved science and philosophy, curious about why we live. After becoming a programmer, I found myself exploring the answer to that question through code.

#### he4o is a spiral entropy-reduction machine, aimed at realizing a general artificial intelligence (AGI) system:

> Manuscript: <https://github.com/jiaxiaogang/HELIX_THEORY> under the manuscript directory

[![](https://img.shields.io/badge/%20QQ-Chat%20-orange.svg)](http://wpa.qq.com/msgrd?v=3&uin=283636001&site=qq&menu=yes)
![](https://img.shields.io/badge/%20Wechat-17636342724%20-orange.svg)

## I. --- Results: DEMO Demonstrations ---

I am middle-aged. Due to daily work and life demands, my remaining time each day is limited; I try to set aside about 30 minutes for HE development. Barring circumstances, I will update it for life. Because my time investment is so small, progress is slow — please temper your expectations.

#### DEMO plan and progress summary:

Some items are completed, some are still in progress, and some are in future plans, as follows:

1. Minimal verification (overall completion 100%).
    - Verify the feasibility of the minimal system. Completed (see HE.v1 release notes).
2. Crow intelligence (overall completion 80%).
    - Foraging, one of the three parts. Completed (see DEMO1 & DEMO3 below).
    - Obstacle avoidance, one of the three parts. Completed (see DEMO2 & DEMO4 below).
    - Tool use, one of the three parts. Completed (see DEMO5 below).
    - Integration of all three parts. Not completed.
3. Vision refinement (overall completion 60%).
    - 1000-pixel baseline. Completed (see DEMO6 & DEMO7 below).
    - Iterative optimization above ten thousand pixels, 80% complete.
4. Toward reality (overall completion 0%).
    - Initial version: some dexterous-hand control. Not completed.
    - Later: a complete robot car or humanoid fusing audio-visual behavior, etc. Not completed.
5. Text training (overall completion 0%).
    - Early version: directly train a language model (intentionality replaced by simulation, scene replaced by context, feedback replaced by continuing the conversation).
    - Initial version: idiom chaining and the like. Not completed.
    - Later: translation, etc. Not completed.

#### Completed DEMO records:

For testing and validation, I made several small demos with GIFs below. More complete demos are still being pushed and refined. Currently he4o supports the following (with explanations):

| DEMO1 | Multi-directional flight-eat |
| --- | --- |
| Description | In this demo, through interaction it has learned that eating nuts when hungry solves the hunger problem, and that flying solves the distance problem. After a nut is tossed out, it flies over on its own to eat it and resolve the hunger. |
| Operation | In this demo I fed two nuts and triggered simulated hunger (because waiting for the phone battery to drain is too slow; I usually run it on an emulator, which also avoids battery drain). Everything else is its own behavior. |
|  | ![](https://github.com/jiaxiaogang/Resource/blob/master/Img/SMG/20210115多向飞行演示.gif?raw=true) |

| DEMO2 | Safety First |
| --- | --- |
| Description | In this demo, after being hit once in prior interaction, the moment it sees a flying wooden stick it dodges immediately, and never flies down again — even if a nut is tossed, it won't go eat it. |
| Operation | I can drag it down with a double-click, but it dodges back up on its own. I can also manually feed it nuts, but it still dodges and won't go over. |
|  | ![](https://github.com/jiaxiaogang/Resource/blob/master/Img/SMG/20210205被撞两下后死活不下来.gif?raw=true) |

| DEMO3 | Changing direction to forage |
| --- | --- |
| Description | In this demo it automatically tries to fly to a nut and eat it. When very close it tries to eat but misses, thinks for a moment, flies closer, then eats the nut. |
| Operation | In this demo I tossed a nut and triggered simulated hunger; everything else is its own thinking and behavior. |
|  | ![](https://github.com/jiaxiaogang/Resource/blob/master/Img/SMG/20230628-多向连续飞吃b.gif?raw=true) |

| DEMO4 | Dodge first, then eat |
| --- | --- |
| Description | In this demo, after getting hungry it goes accurately to eat, but upon seeing a wooden stick it immediately dodges back, waits for the stick to pass and become safe, then flies up to eat the nut. |
| Operation | I tossed the nut, triggered hunger, and threw the stick; everything else is its own. |
|  | ![](https://github.com/jiaxiaogang/Resource/blob/master/Img/SMG/20230730-觅食途中遇险躲等安全再去吃.gif?raw=true) |

| DEMO5 | First use of tools |
| --- | --- |
| Description | In this demo it can kick a nut with a shell onto the road by a kicking action, wait for a rolling stick to crush the shell (a rudimentary tool-use function), then fly over to eat it. |
| Operation | I tossed the shelled nut, triggered hunger, and threw the stick; everything else is its own. |
|  | ![](https://github.com/jiaxiaogang/Resource/blob/master/Img/SMG/20240809-自行踢坚果到路上和飞吃.gif?raw=true) |

| DEMO6 | Vision recognition DEMO1 - mouse recognition |
| --- | --- |
| Description | In this demo, the system was shown 12 different handwritten "0"s and 12 mouse photos, then asked to recognize a new-style mouse — to see whether it could tell it was more like a mouse or more like a "0". |
| Operation | No operation; just let it look at 12 handwritten "0"s and mouse photos I shot myself. |
| Link | I recorded the detailed explanation at the following link; click to view the document for section 34142. |
|  | https://zhuanlan.zhihu.com/p/1897085669467206936 |

| DEMO7 | Vision recognition DEMO2 - multi-object recognition |
| --- | --- |
| Description | In this demo it was shown photos of handwritten "0", cups, gamepads, cats, and drinks — five of each. During the process it looked, learned, and recognized simultaneously. On the first photo it didn't recognize the object, but by the fifth photo it could fairly stably recognize what it was. |
| Link | https://zhuanlan.zhihu.com/p/1898510362254500051 |

***

## II. --- Feature Description ---

Currently the he4o system already supports: **senses, recognition, prediction, feedback, learning, induction, analogy, reinforcement learning, transfer learning, value-sense, intentionality, planning, solving, fast response to environmental change, decision-making, behavior, reflection, evaluation, dynamic lifelong learning, sparse representation, features, concept-from-senses, concept-from-limbs, value-sense concepts, scene timing, solution timing, abstract-concrete relations, macro-micro, nesting, and more**.

1. Machine learning support:
   - Transfer learning as the mainstay (structure) (math: set theory)
   - Reinforcement learning as a supplement (competition) (math: probability theory)
2. Network knowledge representation support:
   - Macro-micro relations: 1. sparse codes, 2. features, 3. concepts, 4. timing, 5. value
   - Abstract-concrete relations: i.e. the relation between generality and individuality.
   - Nesting relations: relations between scenes and solutions (i.e. changes of scenes).
   - Sensibility-reason relations: sensibility (intentionality) and reason.
3. Network knowledge evolution support: embodied (including perception I and limbs O), autonomous, lifelong, dynamic, fuzzy.
4. Both the macro framework and the micro details follow relativity and cyclic transformation.
5. Thinking-control support:
   - I/O (behavior & perception) // including feedback
   - Cognition (recognition & learning) // including analogy
   - Demand (task & plan) // including intention
   - Decision (solving & judging) // including reflection
6. Computation: uses the simplest boolean operations: `analogy` and `evaluation`.
7. Memory structure: long-term as a network (heuristic), short-term as a tree (recursive), instantaneous as a sequence (in order).
8. Programming paradigm: DOP (Dynamic-Oriented Programming).
    - Knowledge evolves post-natally; only controllers and storage structures are written pre-natally.
    - The innate is the vessel; the acquired is the use.
    - DOP is the opposite of OOP: OOP abstracts first then concretizes; the first half of DOP finds abstractions from concretes, and only the second half solves concretes with abstractions.
9. Performance requirement: runnable on a single terminal (currently an iOS device) (relies more on disk I/O than computation).

***

## III. --- Open-Source Statement & Paid Statement ---

1. Released under the LGPL [![License](https://img.shields.io/badge/license-GPL-blue.svg)](LICENSE) open-source license.
2. For commercialization, contact the author for a commercial license, but commercialization only grants authorization for the application layer and similar (final interpretation rights belong to the author).
3. Giveback clause: any development based on this system — this system has the right to unconditionally absorb any code it deems useful into itself.
4. Payment: this software in whole or in part, and software applications derived on the basis of the spiral theory, are free for individuals and paid for commercial use. Commercial fee standard: 0.1% of the product's listed price.
5. Donations: you may tip me; this support is very important to me, helping me devote more funds and energy to R&D on this system. Thank you very much.
  * 2024.06 thanks to REmaiin (you who endure the time, boy?) 10.6 yuan
  * 2024.12 thanks to REmaiin 66 yuan
  * 2025.01 thanks to *NIKOLAI 30 yuan
  * ![](assets/支付宝收款码.png)

## IV. --- Spiral Theory & Model ---

> Full name of spiral theory: Spiral Entropy-Reduction Theory.
> Spiral theory was formally started in February 2017 and matured in February 2018, taking one year; the model matured in March 2018.

| Spiral theory: comprises three elements — definition, relativity, and cycle — jointly presenting a spiral form. |
| --- |
| https://github.com/jiaxiaogang/HELIX_THEORY?tab=readme-ov-file#%E8%9E%BA%E6%97%8B%E7%86%B5%E5%87%8F%E7%90%86%E8%AE%BA |

| Model: relative cycles from inside out, broken down into the following spiral model diagram. |
| --- |
| ![](https://github.com/jiaxiaogang/HELIX_THEORY/blob/master/手稿/assets/508_%E4%BF%A1%E6%81%AF%E7%86%B5%E5%87%8F%E6%9C%BA202107%E5%8A%A8%E5%9B%BE%E7%89%88.gif?raw=true) |
| 1. This diagram is interpreted from three angles: inner-outer bidirectional, dynamic-static transformation, and subject-object perspective. |
| 2. Each outer module is in a relative cycle with the sum of all inner modules (e.g. neural network vs. thinking, agent vs. real world). |
| Note: everything goes from nothing to something, through relativity and cycles. |
| E.g.: he4o considers itself alive `derived from the cycle`. |

<br>

## V. --- HE System Practice ---

The HE system is an implementation based on spiral theory. The name means the pinyin of "和" (harmony) and is also the prefix of HELIX (spiral).

##### 1. Initial version: project started `Feb 2017` — officially released V1.0 on `Oct 21, 2018`.
##### 2. Bird survival demo: `Nov 2018` — `end of 2024`.
##### 3. Pushing vision to maturity: `early 2025` — `present`.
##### 4. Pushing marketization: `in preparation`.

| Architecture diagram | ![](https://github.com/jiaxiaogang/HELIX_THEORY/raw/master/手稿/assets/730_HE%E6%9E%B6%E6%9E%84%E5%9B%BEV5.png) |
| --- | --- |
| Practice note | Theory goes from inside out, practice from outside in, and the two connect (e.g. the more detailed, the more it leans toward feasibility exploration rather than being fully explained by theory) |
| Architecture design | Spiral theory unfolds into the spiral entropy-reduction machine model, which then unfolds into the system architecture |
| Code proportion | In kernel code, neural network accounts for 30%, thinking controller 50%, others (input, output, etc.) 20% |
| Neural network | Ten-character summary of the neural network model: `macro-micro horizontally, abstract-concrete vertically` |
| Thinking polarity | Each operation direction represents a thinking operation, e.g.: cognition, decision, reason, sensibility |
| Thinking modules | `1-2-4-8: perception (in), recognition (cognition), learning (knowledge), task (demand), plan (seek), solve (decide), transfer (strategy), behavior (out)` |
| Thinking architecture | The thinking controller as a whole runs in a spiral form |

***

## VI. --- Summary ---

I am merely a programmer; please don't have overly high expectations of me. I'm not doing scientific research — I'm just writing code for an AI system I believe in. Thank you for understanding.

**Note: Since the 1950s, humanity's 70 years of AI research history has had its ups and downs. I personally prefer to split it into two starting points:**

1. One leans toward reinforcement-competition self-programming genetics, mainly achieving more correct results through dynamic competition of compute power to manifest intelligence.
2. The other leans toward rule-based inference and behavior control, mainly achieving more fitting results through designed fixed rules to manifest intelligence.

**Problem: the former is too loose, the latter too rigid.**

3. Recently the former has started moving toward the latter, adding annotation graphs, Go rules, natural-language rules, and inference rules.
4. And the latter has started moving toward the former, adding manual knowledge bases, preprocessed knowledge, world models, and embodiment.

**Approach: we combine the strengths of both.**

5. I believe there is a balance point between the two, which uses carefully designed code rules innately and runs dynamic lifelong-acquired knowledge data post-natally.
6. I have been looking for such a balance point, making the two cooperate like the left and right hand, and designed an ascending mechanism so the two form a virtuous cycle, spiraling upward.

**Elements: what should an AI system have?**

7. I believe AI's thinking should have: "perception, recognition, prediction, feedback, reinforcement, learning, value-sense, intentionality, planning, solving, transfer, reflection, evaluation, decision, behavior, etc."
8. AI's knowledge representation should have: "sparse representation, features, concepts, scene timing, timing change, value-sense, abstract-concrete, etc."
9. In effect, it should at least be able to learn dynamically, learn lifelong, and respond promptly to environmental change.

**Status: what has the industry achieved?**

10. Current AI results are still far from the AI originally envisioned, and fall far short of having all the above.
11. The hottest GPT is only an AI of the text world; multimodality is poorly done — only senses, maybe 20%; other modules even less.

**Plan: what does this system aim to achieve?**

12. Over 8 years, he4o has basically achieved nearly all of the above, though many engineering details and pitfalls are still being fixed. Complex demos often get stuck on bugs, while simple demos aren't impressive — and the public only cares about results.
13. he4o aims to realize a general artificial intelligence system in the form of a spiral entropy-reduction machine.


## VII. --- Development: Timeline ---

> ##### 2026.05.19 `to present`
* ST competition-factor main/auxiliary mechanism
* Progressive elimination method
* Vision and kernel integration
* Unknown fear (unknown) mv
* Focus on behavioral reflex response
* Feature-concept changed to inheritance relation

> ##### 2026.04.11 `38 days`
* Shift from absolute accuracy to competition-emergence as the standard
* Image intensive-training tool
* Vision-attention thinking cycle
* Discard GT module

> ##### 2026.03.07 `34 days`
* GT bootstrap switched to GV cut-implementation
* Weighted-sum cut method
> - GT bootstrap cut-implementation, weighted-sum cut method: `fix ST & GT misalignment & low match rate`, `GT bootstrap dimension-reduction to GV layer`, `GT analogy dimension-reduction to GV layer`, `GT bootstrap via cut-implementation`, `new competition factors: integrity and stability`, `weighted-sum cut method (adsorption cut algorithm)`

> ##### 2026.01.24 `41 days`
> - Improve feature-recognition accuracy: `change GT recognition pathway to fix low collision rate`, `tune ST & GT recognition competition-factor parameters`, `GT recognition position-conformity`, `GT valid abstraction`

> ##### 2025.12.29 `25 days`
* Feature recognition: accurate-first, then concrete
* Take valid abstraction (full containment of similar layer)
> - `test feature-evolution competition emergence`, `ST recognition inaccuracy issue`, `feature recognition changed to: accurate-first then concrete (prefer concrete layer) & take valid abstraction (full similar-layer result)`

> ##### 2025.11.26 `33 days`
* Misalignment issue
* Anti-dup pool
> - Test & optimize feature recognition: `test: feature-evolution competition emergence`, `BUG: simplify GT recognition ref pathway, feature-recognition entry-point over-anti-dup issue, ProtoGT malformation, misalignment offset issue`, `optimize: sparse-code recognition algorithm, feature-recognition performance, anti-dup index anti-dup pool`

> ##### 2025.10.22 `33 days`
* Tune competition-factor parameters
> - Test/fix BUG & refine details: `feature-evolution competition emergence`, `GT hard-to-recognize issue: simplify GT recognition ref pathway`, `ProtoGT malformation issue: ST anti-abstract-concrete low-value down-weight`

> ##### 2025.09.04 `48 days`
* Support GT module
* ST partition balanced competition
> - Iterate: `group-feature reverted to independent network module`, `single-feature partition balanced competition`

> ##### 2025.07.29 `35 days`
* GT supports bootstrap
> - Iterate: `group-feature recognition switched to bootstrap`

> ##### 2025.06.11 `48 days`
* Discard GT module
> - Iterate: `adaptive granularity — discard group feature`

> ##### 2025.05.08 `33 days`
* Support GT module
> - Test: `test adaptive-granularity version`, `iterate to support group feature`

> ##### 2025.04.23 `15 days`
* Vision visualization tool
* Adaptive granularity
> - Continue training DEMO & iterate vision version: `multi-feature fast extraction`, `vision visualization debug tool`, `adaptive-granularity version iteration`

> ##### 2025.04.13 `10 days`
* Multi-object recognition vision DEMO
> - Regression-test & optimize training DEMO: `regression-test similar-layer group-feature recognition and analogy`, `vision DEMO1: mouse recognition success`, `optimize group-code index`, `vision DEMO2: multi-object recognition success`

> ##### 2025.03.22 `19 days`
* Feature similar-layer recognition and analogy
> - Regression-test & optimize details: `regression-test multi-code feature: build & recognize & analogy & abstract`, `iterate sparse-code index: group-code index`, `test reasonable abstraction degree of feature & test group-code index`, `iterate to support feature similar-layer recognition and analogy (single feature looks for group feature toward similar layer)`

> ##### 2025.03.15 `6 days`
* Support multi-code feature: feature representation, feature recognition, feature analogy
* Sensory algorithm model
> - Multi-code feature: `support multi-code feature`, `sensory algorithm & sensory model`, `group-code representation & feature representation`, `group-code recognition & feature recognition`, `group-code analogy & feature analogy`

> ##### 2025.02.27 `16 days`
* Simplify H nesting
* Transfer iteration: inherit only from FScene
> - Iterate details: `simplify H nesting`, `iterate OutSPDic representation`, `discard transfer virtual-to-real (IScene layer does not hang Canset)`, `Solution inherits only from FScene`, `iterate CansetV3 analogy`, `test the simplified nesting, OutSPDic data structure, solving only from FScene, CansetV3 analogy, etc.`

> ##### 2025.01.08 `49 days`
> - Iterate details: `clarify & refine: H-transfer follows R-transfer associations`, `iterate hSolutionV4: expand solving range and fix transfer path`, `test hSolutionV4 (found H-nesting complexity issue)`

> ##### 2024.11.21 `47 days`
> - Test/fix BUG: `continue trial-and-error training`, `optimize performance & SP huge BUG and several other BUGs`, `abstract-concrete timing match-rate empty BUG`, `test directed-distanceless scene competition emergence`, `RealCansetTo mapping duplicate element BUG`

> ##### 2024.10.11 `40 days`
> - Regression test: `continue trial-and-error training`, `found post-second-filter diversity-disappears BUG`, `timing-recognition similar-layer-ization`, `iterate transfer: recommend-at-learn & inherit-at-use`, `child is father, father is not child`, `I/F combined stability calculation`

> ##### 2024.09.10 `30 days`
> - Iterate details: `iterate Canset analogy algorithm`, `fix outSPDic BUGs`, `TCPlan supports reflection R subtask`, `enable iterative precondition satisfaction`, `iterate timing full-containment algorithm`

> ##### 2024.08.09 `30 days`
> - Comprehensive training: `continuous multi-direction foraging`, `turn on protoFo global anti-dup`, `refine TCPlanV2 flow details`, `trial-and-error training`, `broad-infection & narrow-count`

> ##### 2024.07.20 `19 days`
> - Regression training: `training-use carrying`, `fine-tune: multi-trigger Canset analogy abstraction`

> ##### 2024.07.06 `14 days`
> - Iterate TCPlanV2 & continuous vision: `training-use carrying (failed)`, `iterate TCPlanV2`, `training-use carrying (success but unstable)`, `continuous vision`

> ##### 2024.05.25 `40 days`
> - Regression training: `testing`, `support OutSPDic`, `train skinless-fruit motive ok`, `train Canset trial-and-error ok`, `train learn-peeling ok`, `train skinned-fruit motive ok`, `fine-tune: failure mechanism of sustained-value-sense task adjusted to — task does not fail after negative mv feedback`, `train learn-carrying`

> ##### 2024.05.10 `15 days`
> - Canset infection mechanism: `Canset infection mechanism: batch-judge-no and batch-wake`

> ##### 2024.04.25 `15 days`
> - Test/train & fix details: `concept-recognition BUG causing feedbackTOR not to hold`, `iterate convert2RCansetModel() algorithm: 1. optimize precondition-satisfaction judgment 2. candidate pool wide-in 100% activation`

> ##### 2024.04.10 `15 days`
> - Canset's IndexDic: `HCanset IndexDic collection and computation`

> ##### 2024.03.12 `28 days`
> - Training test: `regression-test real-time competition and HSolutionV3`

> ##### 2024.02.15 `25 days`
> - Iterate hSolutionV3: `iterate hSolutionV3`, `iterate transfer: comprehensive indexDic computation & recommend-inherit merge`

> ##### 2024.01.10 `25 days`
> - Real-time solution competition: `support sustained feedback & sustained-feedback evaluation`, `Cansets real-time competition`, `iterate TCPlanV2`

> ##### 2023.12.28 `12 days`
> - Carrying training: `carrying-motive training`, `learn carrying`, `apply carrying`, `Root competition progress-score weighting`, `hCanset transfer optimization: implement transfer based on r-scene tree and hAlg abstract-concrete tree`

> ##### 2023.11.09 `49 days`
> - Carrying training: `carrying-motive training`, `interlayer Canset training`, `plan carrying-training steps`, `transfer also transfers SP value`, `build Canset changed to in-scene anti-dup`, `same-type task executed too many times issue: same-type Root merge`, `decision performance optimization (15s to 1s)`

> ##### 2023.10.17 `22 days`
> - Peeling training: `organize Canset evolution process`, `discard Canset recognition analogy`, `weight Canset pre-imagination and actual analogy`, `fully support common-abstraction of cansetAlg i.e. matching`, `actual fo in pre-vs-actual analogy: generated using pFo.realMaskFo`

> ##### 2023.09.07 `40 days`
> - Peeling training: `H task supports TCScene & TCCanset & TCTransfer`, `HCanset changed from R-scene to standalone scene`, `optimize peeling-training steps`

> ##### 2023.08.16 `20 days`
> - Peeling training: `learn peeling`, `training-step design and implementation`

> ##### 2023.07.30 `17 days`
> - Peeling training: `peeling motive`

> ##### 2023.07.16 `14 days, of which 7 days testing`
> - Multi-threaded thinking: `thinking uses TI and TO two threads`, `regression test-train`

> ##### 2023.06.29 `17 days`
> - Test parent-child tasks: `iterate TCRefrection reflection: move to before behavioralization`, `reflection-recognition second filter`

> ##### 2023.06.01 `28 days`
> - Anti-collision and foraging training, safe-then-eat training: `performance optimization`, `anti-collision training ok`, `foraging training ok`, `anti-collision + foraging joint training ok`, `sustained hunger sense`

> ##### 2023.05.25 `7 days`
> - Recognition-accuracy improvement: `recognition second filter`

> ##### 2023.05.07 `18 days`
> - Regression-test Solution dataflow competition evolution: `train-test stable scene evolution process`, `iterate solutionFoRank ranker`

> ##### 2023.05.03 `4 days`
> - Sort out TO dataflow: `Solution competition fault: wide-in narrow-out`, `solutionCanset filter`, `solutionScene filter`

> ##### 2023.04.20 `12 days`
> - Canset transferability enhancement regression-test: `fix canset post-transfer support indexDic and other BUGs`

> ##### 2023.04.02 `18 days`
> - Enhance Canset transferability — decision part: `Canset transferability-enhanced decision support`, `TCScene scene tree`, `TCCanset.override algorithm`, `TCRealact feasibility`, `TCTransfer recommend and inherit algorithm`, `correspondingly update SPEFF`

> ##### 2023.03.21 `11 days`
> - Enhance Canset transferability — cognition part: `outer analogy supports match-degree common points`, `build new Canset preferentially using scene alg`, `iterate Canst recognition & full-containment judgment`, `Canst outer analogy`, `Canst empty concept`, `abstract Canset initial SPEFF`, `Canset recognition supports AIFilter`, `regression-test Canset transferability`

> ##### 2023.03.09 `12 days`
> - Training: `foraging and anti-collision training`, `feature subjective constancy`, `Canset inertia period`, `found Canset transferability-poor issue`

> ##### 2023.02.26 `13 days`
> - Optimization: `test decision-cycle continuous fly-dodge`, `reflection subtask not solving`, `BUG_behavior-to-task infinite loop`, `BUG_silent task activated`, `adjust filter to improve recognition accuracy`, `foraging training planning: mv into timing (incomplete)`, `increase transferability and recognition accuracy: discard objective features`

> ##### 2023.02.14 `12 days`
> - Optimization: `make taking S increasingly accurate`, `low-recognition-rate BUG`, `support AIFilter`

> ##### 2023.02.04 `10 days`
> - Regression test: `test precondition-satisfaction feature`, `regression-test item big-cleanup`, `fix R-task Canset re-analogy timing and condition-judgment BUG`

> ##### 2023.01.03 `12 days (including 12 days testing, with 7 days off for Spring Festival midway)`
> - Optimization: `iterate canset precondition satisfaction`, `make concept recognition increasingly accurate`, `fix incomplete precondition-satisfaction issue`

> ##### 2022.12.17 `16 days`
> - AIRank: `comprehensive competition of concept recognition and timing recognition: support strength competition`, `regression test`

> ##### 2022.11.30 `17 days`
> - Twentieth test: `regression test`

> ##### 2022.10.15 `45 days`
> - Optimization: `abstract-concrete multi-layer diversity optimization`, `persist and reuse concept similarity`, `iterate timing recognition: persist and reuse indexDic`, `canset evolution cycle`, `abolish TO reflection recognition`

> ##### 2022.10.08 `7 days`
> - Testing: `discard isMem`, `continue testing reflection`

> ##### 2022.09.18 `12 days`
> - Testing: `test task-failure mechanism`

> ##### 2022.09.01 `17 days`
> - Tuning: `task-failure mechanism`

> ##### 2022.08.06 `25 days`
> - Testing: `test TCRefrection`, `performance optimization`

> ##### 2022.07.05 `22 days, with 8 days off for travel midway`
> - Nineteenth test: `iterate TCRefrection reflection`

> ##### 2022.06.05 `9 days, with 20 days off for pandemic midway`
> - Sort out TC dataflow: `decision-config tuning: fast/slow thinking part`, `count-at-learn & probability-at-use`, `test continuous fly-dodge`, `Analyst comprehensive ranking`

> ##### 2022.05.20 `15 days`
> - Sort out TC dataflow: `recognition-accuracy optimization: layer-wise wide-in narrow-out`, `dataflow: holistic view`, `fast thinking / slow thinking`, `TCActYes per-frame O introspection`

> ##### 2022.05.11 `9 days`
> - Performance optimization: `optimize pFo recognition performance`, `iterate Demand to support multi-pFos`, `eighteenth-test regression test`

> ##### 2022.05.04 `7 days`
> - Tool optimization: `seventeenth test`, `RL trainer optimization: support simulated restart`, `thinking-visualization tool optimization: support gesture zoom`

> ##### 2022.04.28 `6 days`
> - Sort out TC dataflow: `holistic balance`, `per-line competition`

> ##### 2022.04.23 `5 days`
> - Sixteenth test: `performance optimization`, `reinforcement-learning training`

> ##### 2022.03.28 `8 days, with 17 days off for pandemic midway`
> - Reinforcement training: `develop RL stability trainer: RLTrainer`

> ##### 2022.03.13 `15 days`
> - Thinking-visualization tool: `TOMVisionV2 iteration: thinking visualization`

> ##### 2022.02.16 `25 days, with 25 days off for Spring Festival/pandemic midway`
> - Fifteenth test: `Spring Festival over, resume regression test`

> ##### 2022.01.15 `5 days`
> - Fourteenth test: `regression-test similar matching`

> ##### 2022.01.10 `5 days`
> - Similar matching: `similar matching`

> ##### 2021.12.26 `15 days`
> - Regression thirteenth test: `new-spiral-architecture test`, `reflection-split iteration test`

> ##### 2021.12.22 `4 days`
> - Reflection iteration: `hSolution takes solution from SP`, `split: sensibility-reflection and reason-reflection`, `discard HN`

> ##### 2021.11.18 `34 days`
> - Thinking-controller architecture major iteration: `refine spiral architecture`, `discard macro-micro decision`, `reflection merged into recognition`, `working-memory tree iteration`, `iterate comprehensive evaluation`, `branch-tip optimal path`

> ##### 2021.11.04 `14 days`
> - R-decision-mode iteration: `FRS evaluator iteration`, `discard dsFo`, `discard PM`, `discard GL`

> ##### 2021.10.19 `15 days`
> - PM stability iteration: `VRS evaluator iteration`, `VRSTarget target correction`

> ##### 2021.09.29 `20 days`
> - v2.0 twelfth test & training: `IRT's SP participates in VRS scoring`, `SP definition changed from smooth/counter to good/bad`, `no reflection in emergency state`, `subjective-objective mutual-blocking issue`, `tir_OPushM iteration: IRT reason failure`

> ##### 2021.09.14 `15 days`
> - Network node type audit: `pointer-integrated type`, `self-check test`, `network at&ds&type error big audit`

> ##### 2021.07.08 `66 days`
> - v2.0 eleventh test & training: `subtask regression test`, `R-decision mode`, `anti-collision training`

> ##### 2021.06.25 `13 days`
> - Subtask detail changes: `subtask occurred-cut point`, `same-level task collaboration`

> ##### 2021.06.05 `17 days`
> - Subtask detail changes: `subtask collaboration`, `subtask refractory period`

> ##### 2021.05.24 `1 month`
> - v2.0 tenth test & training: `subtask test`, `anti-collision training`

> ##### 2021.04.10 `44 days`
> - v2.0 ninth test & training: `foraging training & changing-direction foraging training`

> ##### 2021.04.07 `15 days`
> - HNGL nesting iteration: `inner-outer analogy iteration v3, v4`, `iterate getInnerV3()`, `RFo abstract-concrete association`

> ##### 2021.03.12 `20 days`
> - v2.0 eighth test & training: `R-mode test`, `foraging + anti-collision fusion training`

> ##### 2021.02.23 `37 days`
> - Decision-reason iteration: `planning decision`, `subtask iteration: reason reflection`, `in-time evaluation`, `nested association`

> ##### 2021.01.30 `4 days`
> - R-decision-mode V3 iteration, reverse-feedback outer analogy

> ##### 2021.01.23 `35 days`
> - v2.0 seventh test & training `anti-collision training`, `R-mode test`

> ##### 2021.01.15 `8 days`
> - In-reflection analogy iteration, R-decision-mode V2 iteration `iterate trigger mechanism: biological-clock trigger`

> ##### 2020.12.24 `20 days`
> - v2.0 sixth test & training `multi-direction flight normal`

> ##### 2020.12.07 `1 month`
> - AIScore evaluator refinement: `timing reason evaluation: FRS`, `sparse-code reason evaluation: VRS`

> ##### 2020.11.07 `1 month`
> - v2.0 fifth test & training

> ##### 2020.10.21 `15 days`
> - TIR_Alg supports multi-recognition

> ##### 2020.09.01 `1 month`
> - v2.0 fourth test & training

> ##### 2020.08.12 `27 days`
> - Out-reflection analogy iteration (DiffAnalogy), biological clock (AITime), PM reason-evaluation iteration v2

> ##### 2020.06.28 `5 days`
> - Decision iteration: PM reason evaluation

> ##### 2020.06.06 `2 months`
> - v2.0 third test & training

> ##### 2020.05.15 `20 days`
> - Decision iteration: (based on `output-period short-term memory` make decision recursion and outer loop cooperate better)

> ##### 2020.04.21 `1 month`
> - Decision iteration: (based on `input-period short-term memory` make decision support four modes)

> ##### 2020.03.31 `1 month`
> - Iterate outer analogy: add reverse-feedback analogy (In-reflection analogy) (build SP positive/negative timing, apply SP to decision's MC, iterate reflection)

> ##### 2020.02.20 `18 days`
> - Sparse-code fuzzy matching

> ##### 2019.12.27 `3 months continuous`
> - v2.0 second test & planning training — regression bird training

> ##### 2019.11.22 `1 month`
> - Reason thinking — reflection evaluation

> ##### 2019.09.30 `2 months`
> - Reason thinking — TOR iteration (behavioralization architecture iteration, support instantaneous network)

> ##### 2019.08.25 `1 month`
> - Reason thinking — TIR iteration (timing recognition, timing prediction, value pre-judgment)

> ##### 2019.06.20 `2 months`
> - v2.0 version basic bug-fixing & training

> ##### 2019.06.05 `15 days to write, 45 days to reach usability standard`
> - v2.0 first test — bird training — neural network visualization v2.0

> ##### 2019.05.01 `1 month`
> - Performance optimization — `XGWedis async persistence` and `short-term memory network`

> ##### 2019.03.01 `2 months`
> - Inner analogy (counterpart to outer analogy)

> ##### 2019.01.21 `40 days`
> - Iterate decision cycle (behavioralization etc.)

> ##### 2018.11.28 `2 months`
> - Iterate neural network (distinguish dynamic timing from static concepts)

> ##### 2018.11.05 `20 days planning`
> - Potential (bird survival demo) (v2.0 development begins)

> ##### 2018.10.21 `0 days`
> - v1.0.0 (he4o kernel release)

> ##### 2018.10.20 `0 days`
> - Spiral entropy-reduction machine (the environment that produces intelligence)

> ##### 2018.08.29 `2 months`
> - MOL

> ##### 2018.08.01 `1 month`
> - MIL & MOL (refactor middle-layer dynamic loop)

> ##### 2018.07.01 `1 month`
> - HELIX (the spiral form presented by definition, relativity, and cycle)

> ##### 2018.06.01 `1 month`
> - Three-layer loop major revision (mv loop, thinking-network loop, agent-and-real-world loop)

> ##### 2018.05.01 `1 month`
> - Relativity (he4o implements definition, horizontal relativity, vertical relativity)

> ##### 2018.02.01 `3 months`
> - Macro-micro (formerly split-and-integrate, macro-micro unified)

> ##### 2017.12.09 `2 months`
> - Definition (from 0 to 1)

> ##### 2017.11.10 `1 month`
> - Rules (minimal)

> ##### 2017.09.20 `50 days`
> - DOP_Data-Oriented Programming
> - GNOP_Dynamic Network Construction

> ##### 2017.08.23 `1 month`
> - Neural network (algorithm, abstract-concrete network)

> ##### 2017.08.02 `20 days`
> - MindValue (value)

> ##### 2017.07.10 `20 days`
> - Tree BrainTree (referring to N3P7, N3P8)

> ##### 2017.06.01 `40 days`
> - Three-dimensional architecture (referring to notes/AI/framework)

> ##### 2017.05.22 `10 days`
> - OOP paradigm -> data language (OOP2DataLanguage)

> ##### 2017.05.21 `1 day`
> - Redrew the new architecture diagram; (AIFoundation)

> ##### 2017.04.21 `1 month`
> - Pyramid architecture

> ##### 2017.03.21 `1 month`
> - Layered architecture

> ##### 2017.02.21 `1 month`
> - Flow architecture
