asset GravityBikeSplineCarEnemyTurretMuzzleRecoilCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	1.0 |      '''''''···..                                              |
	    |     .            ''··.                                         |
	    |                       '··.                                     |
	    |                           '·..                                 |
	    |    .                          '·.                              |
	    |                                  '·.                           |
	    |                                     '·.                        |
	    |                                        '.                      |
	    |   ·                                      '·.                   |
	    |                                             '·.                |
	    |                                                '.              |
	    |                                                  '·.           |
	    |  '                                                  '·         |
	    |                                                       '·.      |
	    | .                                                        '·.   |
	0.0 |.                                                            '·.|
	    ------------------------------------------------------------------
	    0.0                                                            1.0
	*/
	AddAutoCurveKey(0.0, 0.0);
	AddAutoCurveKey(0.1, 1.0);
	AddAutoCurveKey(0.1, 1.0);
	AddCurveKeyTangent(1.0, 0.0, -1.411555);
};

UCLASS(NotBlueprintable, NotPlaceable)
class UGravityBikeSplineCarEnemyTurretMuzzleComponent : UArrowComponent
{
	const float RecoilDuration = 0.2;
	const float RecoilDelta = -65;
	float LastFireTime = -1;
	FVector InitialRelativeLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialRelativeLocation = RelativeLocation;
	}
};