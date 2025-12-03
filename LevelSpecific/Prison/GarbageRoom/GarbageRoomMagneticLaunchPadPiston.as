UCLASS(Abstract)
class AGarbageRoomMagneticLaunchPadPiston : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PistonRoot;

	UPROPERTY(DefaultComponent, Attach = PistonRoot)
	USceneComponent TranslationRoot;

	UPROPERTY(DefaultComponent, Attach = TranslationRoot)
	UDynamicWaterEffectDecalComponent WaterDecalComp;
	default WaterDecalComp.Speed = 20.0;
	default WaterDecalComp.Contrast = 3.0;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveTimeLike;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveTimeLike.BindUpdate(this, n"UpdateMove");
		MoveTimeLike.PlayFromStart();
	}

	UFUNCTION()
	private void UpdateMove(float CurValue)
	{
		float Offset = Math::Lerp(0.0, 250.0, CurValue);
		FVector Loc = PistonRoot.WorldLocation + (TranslationRoot.UpVector * Offset);
		TranslationRoot.SetWorldLocation(Loc);

		UpdateWaterDecal(CurValue);
	}

	void UpdateWaterDecal(float CurValue)
	{
		// make sure its 0 to 1
		float RemappedProgressValue = Math::Saturate(CurValue);

		// transform linear progression to bell curve progression
		float BellCurveWidth = 0.2;
		RemappedProgressValue = Math::Exp(-Math::Square(RemappedProgressValue-0.5) / (2.0 * Math::Square(BellCurveWidth)));

		WaterDecalComp.Strength = RemappedProgressValue * 30.0;
	}

}