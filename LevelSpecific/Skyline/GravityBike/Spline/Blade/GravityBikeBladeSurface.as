asset GravityBikeBladeSurfaceTimeDilationCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	1.0 |''''                                                      ''''''|
	    |    ''                                                 '''      |
	    |      '                                              ''         |
	    |       ''                                          ''           |
	    |         '                                       ''             |
	    |          '                                     '               |
	    |           '                                  ''                |
	    |            '                                '                  |
	    |             '                             ''                   |
	    |              '                          ''                     |
	    |               '                        '                       |
	    |                '                     ''                        |
	    |                 ''                 ''                          |
	    |                   '              ''                            |
	    |                    ''         '''                              |
	0.5 |                      '''''''''                                 |
	    ------------------------------------------------------------------
	    0.0                                                            1.0
	*/
	AddCurveKeyTangent(0.0, 1.0, 0.0);
	AddAutoCurveKey(0.4, 0.5);
	AddLinearCurveKey(1.0, 1.0);
};

UCLASS(Abstract)
class AGravityBikeBladeSurface : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.Mobility = EComponentMobility::Static;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UGravityBikeBladeTargetComponent BladeTargetComp;
	default BladeTargetComp.Mobility = EComponentMobility::Static;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;
	default MeshComp.Mobility = EComponentMobility::Static;

	UPROPERTY(EditInstanceOnly, Category = "Gravity Blade Surface")
	AHazeCameraActor GrappleCameraActor;
};