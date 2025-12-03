class ABallistaHydraSplinePlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateCompZ;
	default TranslateCompZ.bConstrainX = true;
	default TranslateCompZ.bConstrainY = true;
	default TranslateCompZ.SpringStrength = 20.0;

	UPROPERTY(DefaultComponent, Attach = TranslateCompZ)
	UFauxPhysicsConeRotateComponent ConeRotateComp;
	default ConeRotateComp.LocalConeDirection = -FVector::UpVector;
	default ConeRotateComp.Friction = 5.0;
	default ConeRotateComp.bConstrainTwist = true;
	default ConeRotateComp.SpringStrength = 0.2;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	USanctuaryFloatingSceneComponent FloatingComp; 

	UPROPERTY(DefaultComponent, Attach = FloatingComp)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;
	default PlayerWeightComp.PlayerForce = 200.0;
	default PlayerWeightComp.PlayerImpulseScale = 0.05;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(BallistaHydraSplinePlatformSheet);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditAnywhere)
	bool bRotating = false;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformTemporalLogComp;
#endif

	UPROPERTY(EditInstanceOnly)
	TOptional<EMedallionPhase> PauseSplineStartPhase;
	UPROPERTY(EditInstanceOnly)
	TOptional<EMedallionPhase> PauseSplineLastPhase;

	UPROPERTY(EditInstanceOnly)
	EMedallionPhase StartFloatToSurfaceDuringPhase;
	UPROPERTY(EditInstanceOnly)
	EMedallionPhase StopFloatToSurfaceDuringPhase = EMedallionPhase::Skydive;

	UPROPERTY(EditInstanceOnly)
	ARespawnPoint CustomRespawnPoint;

	UPROPERTY(EditInstanceOnly)
	EBallistaHydraMeteorTargetType MeteorTargetType;

	UPROPERTY(EditAnywhere, meta = (EditCondition="bRotating", EditConditionHides))
	FRotator RotationPerSecond;

	UPROPERTY(EditDefaultsOnly)
	bool bAllowRespawnOn = true;

	UPROPERTY(EditInstanceOnly)
	float PauseBeforeSinkingDistance = -1.0;

	UPROPERTY()
	float WeightMultiplier = 1.0;

	float RelativeToSplineDistance;
	float RelativeToSplineSideways;
	float RelativeToSplineHeightwise;
	float OriginalHeightOffset = 0.0;
	float PlatformCurrentSplineDist = 0.0;

	ABallistaHydraSpline ParentSpline;

	bool bLaunchPlatform = false;

	bool GetIsUnderWater() const
	{
		const float Treshold = 10.0;
		float CurrentHeightOffset = ActorLocation.Z - ParentSpline.ActorLocation.Z;
		return CurrentHeightOffset < OriginalHeightOffset - Treshold;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (PauseSplineStartPhase.IsSet())
		{
			devCheck(PauseBeforeSinkingDistance > 0.0, ActorNameOrLabel + " has no PauseBeforeSinkingDistance specified!");
		}
	}
};