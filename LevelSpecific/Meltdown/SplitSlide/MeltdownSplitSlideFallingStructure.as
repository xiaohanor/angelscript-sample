class AMeltdownSplitSlideFallingStructure : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USceneComponent ScifiStructureRoot;

	UPROPERTY(DefaultComponent, Attach = ScifiStructureRoot)
	USceneComponent ScifiStructureRollRoot;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent FantasyStructureRoot;
	
	UPROPERTY(DefaultComponent, Attach = FantasyStructureRoot)
	USceneComponent FantasyStructureRollRoot;

	UPROPERTY(DefaultComponent, Attach = FantasyStructureRollRoot)
	USceneComponent FantasyStructureCrushRoot;

	UPROPERTY()
	FHazeTimeLike FallingTimeLike;
	default FallingTimeLike.UseSmoothCurveZeroToOne();

	UPROPERTY()
	FHazeTimeLike RollingTimeLike;
	default FallingTimeLike.UseSmoothCurveZeroToOne();

	UPROPERTY()
	UCurveFloat RollCurve;

	UPROPERTY(EditInstanceOnly)
	AMeltdownMissileBird MissileBird;

	float FallingDegrees = 75.0;
	float RollDegrees = -120.0;
	float YawDegrees = 10.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		FallingTimeLike.BindUpdate(this, n"FallingTimeLikeUpdate");
		FallingTimeLike.BindFinished(this, n"FallingTimeLikeFinished");
		RollingTimeLike.BindUpdate(this, n"RollingTimeLikeUpdate");
		RollingTimeLike.BindFinished(this, n"RollingTimeLikeFinished");
		MissileBird.OnMissileExploded.AddUFunction(this, n"HandleMissileExplode");
	}

	UFUNCTION()
	private void HandleMissileExplode()
	{
		Collapse();
	}

	UFUNCTION()
	void Collapse()
	{
		FallingTimeLike.Play();
		BP_Collapse();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Collapse(){}

	UFUNCTION()
	private void FallingTimeLikeUpdate(float CurrentValue)
	{
		FantasyStructureRoot.SetRelativeRotation(FRotator(Math::Lerp(0.0, FallingDegrees, CurrentValue), 0.0, 0.0));
		ScifiStructureRoot.SetRelativeRotation(FRotator(Math::Lerp(0.0, FallingDegrees, CurrentValue), 0.0, 0.0));
	}

	UFUNCTION()
	private void FallingTimeLikeFinished()
	{
		RollingTimeLike.Play();
		BP_FallFinished();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_FallFinished(){}

	UFUNCTION()
	private void RollingTimeLikeUpdate(float CurrentValue)
	{
		float RollAlpha = Math::Lerp(0.0, RollDegrees, RollCurve.GetFloatValue(RollingTimeLike.GetPosition()));
		float YawAlpha = Math::Lerp(0.0, YawDegrees, 1.2 * RollCurve.GetFloatValue(RollingTimeLike.GetPosition()));
		float PitchAlpha = Math::Lerp(FallingDegrees, 1.5 * FallingDegrees, CurrentValue);

		FantasyStructureRoot.SetRelativeRotation(FRotator(PitchAlpha, YawAlpha, 0.0));
		FantasyStructureRollRoot.SetRelativeRotation(FRotator(0.0, RollAlpha, 0.0));
		ScifiStructureRoot.SetRelativeRotation(FRotator(PitchAlpha, YawAlpha, 0.0));
		ScifiStructureRollRoot.SetRelativeRotation(FRotator(0.0, RollAlpha, 0.0));
	}

	UFUNCTION()
	private void RollingTimeLikeFinished()
	{
		BP_RollFinished();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_RollFinished(){}
};