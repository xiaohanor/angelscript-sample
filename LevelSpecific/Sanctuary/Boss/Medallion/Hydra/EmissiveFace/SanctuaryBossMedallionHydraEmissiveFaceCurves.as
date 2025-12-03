asset SanctuaryBossMedallionHydraEmissiveFaceCurve_LaunchProjectileSingle of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	5.0 |                                                      ..··''''''|
	    |                                                  .·''          |
	    |                                              .·''              |
	    |                                           .·'                  |
	    |                                        .·'                     |
	    |                                     .·'                        |
	    |                                   .'                           |
	    |                                .·'                             |
	    |                             .·'                                |
	    |                           .'                                   |
	    |                        .·'                                     |
	    |                     .·'                                        |
	    |                  .·'                                           |
	    |              ..·'                                              |
	    |          ..·'                                                  |
	0.0 |......··''                                                      |
	    ------------------------------------------------------------------
	    0.0                                                            0.5
	*/
	AddAutoCurveKey(0.0, 0.0);
	AddAutoCurveKey(0.5, 5.0);
}

asset SanctuaryBossMedallionHydraEmissiveFaceCurve_LaunchProjectileTriple of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	5.0 |                    ·'''·                   ·'·               ·'|
	    |                  .'     '                 .   .             .  |
	    |                 ·        ·                                     |
	    |                '          .              .     .           .   |
	    |               '                                                |
	    |              '             '                                   |
	    |             '               .           '       '         '    |
	    |            '                                                   |
	    |           '                  ·         ·         ·       ·     |
	    |          ·                    .                                |
	    |         ·                             ·           ·     ·      |
	    |        ·                       ·                               |
	    |       '                         ·    ·             ·   ·       |
	    |     .'                           ·  .               . .        |
	    |    ·                              '·                 ·         |
	0.0 |..·'                                                            |
	    ------------------------------------------------------------------
	    0.0                                                            0.7
	*/
	AddAutoCurveKey(0.0, 0.0);
	AddCurveKeyTangent(0.25, 5.0, 0.347211);
	AddAutoCurveKey(0.4, 0.5);
	AddAutoCurveKey(0.5, 5.0);
	AddAutoCurveKey(0.6, 0.5);
	AddAutoCurveKey(0.7, 5.0);
}

asset SanctuaryBossMedallionHydraEmissiveFaceCurve_GhostLaser of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	10.1|   '''''··'''''''····'''''''''''''''''''''''''''''''''''''''''''|
	    |                                                                |
	    |  ·                                                             |
	    |                                                                |
	    |                                                                |
	    |                                                                |
	    |                                                                |
	    |                                                                |
	    |                                                                |
	    |                                                                |
	    | .                                                              |
	    |                                                                |
	    |                                                                |
	    |                                                                |
	    |                                                                |
	0.0 |.                                                               |
	    ------------------------------------------------------------------
	    0.0                                                           12.0
	*/
	AddAutoCurveKey(0.0, 0.0);
	AddCurveKeyTangent(0.5, 10.0, -0.001754);
	AddCurveKeyTangent(2.2, 10.0, 0.317865);
	AddCurveKeyTangent(4.0, 10.0, 0.555556);
	AddCurveKeyTangent(6.2, 10.0, 0.234392);
	AddCurveKeyTangent(9.0, 10.0, 0.169086);
	AddCurveKeyTangent(10.6, 10.0, 0.24766);
	AddCurveKeyTangent(12.0, 10.0, 0.0);
}

