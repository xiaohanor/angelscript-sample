
struct FCoastBossPlayerBulletData
{
	FVector2D Location;
	FVector2D Velocity;
}

struct FCoastBossGunBulletData
{
	float ShootAngle = 0.0;
	float BulletSpeed = 0.0;
	bool bUseTopGun = true;
	bool bUseLeftGun = true;
}

enum ECoastBossGunRotatePrio
{
	Lowest,
	Low,
	Medium,
	High,
	Highest,
}

struct FCoastBossGunRotateData
{
	ECoastBossGunRotatePrio Prio = ECoastBossGunRotatePrio::Lowest;
	bool bUseBossPitchRot = false;
	float TargetShootAngle = 0.0;
	float OverrideDuration = 0.0;
}

asset CoastBossWaveDownCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	1.0 |..........                                                      |
	    |          ....                                                  |
	    |              ....                                              |
	    |                  ...                                           |
	    |                     ...                                        |
	    |                        ...                                     |
	    |                           ..                                   |
	    |                             ...                                |
	    |                                ...                             |
	    |                                   ..                           |
	    |                                     ...                        |
	    |                                        ...                     |
	    |                                           ...                  |
	    |                                              ....              |
	    |                                                  ....          |
	-1.0|                                                      ..........|
	    ------------------------------------------------------------------
	    0.0                                                            1.0
	*/
	AddAutoCurveKey(0.0, 1.0);
	AddAutoCurveKey(1.0, -1.0);
}


asset CoastBossWaveUpCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	1.0 |                                              ..................|
	    |                                        ......                  |
	    |                                   .....                        |
	    |                              .....                             |
	    |                           ...                                  |
	    |                       ....                                     |
	    |                    ...                                         |
	    |                  ..                                            |
	    |               ...                                              |
	    |             ..                                                 |
	    |          ...                                                   |
	    |        ..                                                      |
	    |      ..                                                        |
	    |    ..                                                          |
	    |  ..                                                            |
	-1.0|..                                                              |
	    ------------------------------------------------------------------
	    0.0                                                            1.0
	*/
	AddCurveKeyTangent(0.0, -1.0, 4.423877);
	AddAutoCurveKey(1.0, 1.0);
}

asset CoastBossRecoilCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	1.0 |      ''''''··.                                                 |
	    |     .         ''·.                                             |
	    |                   '··                                          |
	    |                      '·.                                       |
	    |    .                    '·.                                    |
	    |                            '·                                  |
	    |                              '·.                               |
	    |                                 '.                             |
	    |   ·                               '·.                          |
	    |                                      ·.                        |
	    |                                        '·                      |
	    |                                          '·.                   |
	    |  '                                          '·.                |
	    |                                                '·.             |
	    | .                                                 '·..         |
	0.0 |.                                                      ''··.....|
	    ------------------------------------------------------------------
	    0.0                                                            1.0
	*/
	AddAutoCurveKey(0.0, 0.0);
	AddAutoCurveKey(0.1, 1.0);
	AddAutoCurveKey(1.0, 0.0);
}

asset CoastBossChargeCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	1.0 |                 ·'''''··.                                      |
	    |               .'         '·.                                   |
	    |              ·              '·.                                |
	    |             .                  ·.                              |
	    |            .                     ·.                            |
	    |                                    ·.                          |
	    |           '                          ·.                        |
	    |          '                             ·                       |
	    |         ·                               '·                     |
	    |        .                                  '·                   |
	    |                                             '.                 |
	    |       '                                       '.               |
	    |      '                                          '·             |
	    |     '                                             '·.          |
	    |   .'                                                 '·.       |
	0.0 |..·                                                      '··....|
	    ------------------------------------------------------------------
	    0.0                                                            1.0
	*/
	AddAutoCurveKey(0.0, 0.0);
	AddAutoCurveKey(0.3, 1.0);
	AddAutoCurveKey(1.0, 0.0);
}

asset CoastBossCrossDownUpCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	0.0 |..                                                            ..|
	    |  .                                                          .  |
	    |   .                                                        .   |
	    |    .                                                      .    |
	    |     ..                                                   .     |
	    |       .                                                ..      |
	    |        .                                              .        |
	    |         ..                                          ..         |
	    |           .                                        .           |
	    |            ..                                    ..            |
	    |              .                                  .              |
	    |               ..                              ..               |
	    |                 ..                          ..                 |
	    |                   ...                    ...                   |
	    |                      ...              ...                      |
	-1.0|                         ..............                         |
	    ------------------------------------------------------------------
	    0.0                                                            1.0
	*/
	AddCurveKeyTangent(0.0, 0.0, -3.465925);
	AddAutoCurveKey(0.5, -1.0);
	AddCurveKeyTangent(1.0, 0.0, 3.516156);
}

asset CoastBossCrossUpDownCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	1.0 |                         ..·''''''''·.                          |
	    |                      .·'             '·.                       |
	    |                    .·                   '·                     |
	    |                  .'                       '·                   |
	    |                .'                           '·                 |
	    |               ·                               '.               |
	    |             ·'                                  ·              |
	    |           .'                                     '.            |
	    |          ·                                         ·           |
	    |         '                                           '.         |
	    |       .'                                              ·        |
	    |      ·                                                 '.      |
	    |    .'                                                    ·     |
	    |   .                                                       '.   |
	    |  ·                                                          ·  |
	0.0 |.'                                                            '.|
	    ------------------------------------------------------------------
	    0.0                                                            1.0
	*/
	AddCurveKeyBrokenTangent(0.0, 0.0, 0.0, 3.020127);
	AddAutoCurveKey(0.5, 1.0);
	AddCurveKeyBrokenTangent(1.0, 0.0, -2.612001, 0.0);
}

asset CoastBossPingPongSpeedCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	1.0 |                                       ......·········''''''''''|
	    |                               ..···'''                         |
	    |                          ..·''                                 |
	    |                       .·'                                      |
	    |                    ·''                                         |
	    |                 .·'                                            |
	    |               ·'                                               |
	    |             ·'                                                 |
	    |           ·'                                                   |
	    |         ·'                                                     |
	    |       .'                                                       |
	    |      ·                                                         |
	    |    .'                                                          |
	    |   ·                                                            |
	    |  ·                                                             |
	0.0 |.'                                                              |
	    ------------------------------------------------------------------
	    0.0                                                            1.0
	*/
	AddCurveKeyTangent(0.0, 0.0, 3.28593);
	AddCurveKeyTangent(1.0, 1.0, 0.221681);
}