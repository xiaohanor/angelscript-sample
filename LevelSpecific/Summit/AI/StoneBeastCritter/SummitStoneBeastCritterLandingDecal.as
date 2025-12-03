class ASummitStoneBeastCritterLandingDecal : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTelegraphDecalComponent DecalComp;
	default DecalComp.bAutoShow = false;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve ScaleCurve;
	default ScaleCurve.AddDefaultKey(0.0, 0.3);
	default ScaleCurve.AddDefaultKey(1.0, 1.0);

	void HideDecal()
	{
		DecalComp.HideTelegraph();
	}

	void ShowDecal()
	{
		DecalComp.ShowTelegraph();
	}
};