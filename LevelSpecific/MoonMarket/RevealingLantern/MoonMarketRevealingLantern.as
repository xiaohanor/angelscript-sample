UCLASS(Abstract)
class AMoonMarketRevealingLantern : AMoonMarketHoldableActor
{
	default InteractableTag = EMoonMarketInteractableTag::Lantern;
	default bShowCancelPrompt = false;
	default bCancelInteractionUponDeath = false;
	default bCancelByThunder = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsConeRotateComponent FauxRotateComp;

	UPROPERTY(DefaultComponent, Attach = FauxRotateComp)
	UFauxPhysicsWeightComponent WeightComp;

	UPROPERTY(DefaultComponent, Attach = FauxRotateComp)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;
	default	MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UStaticMeshComponent GlassMesh;
	default	GlassMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UPointLightComponent PointLight;

	FLinearColor DefaultEmissiveTint;
	FLinearColor CurrentPumpkinEmissiveTint;

	UMaterialInstanceDynamic DynamicPumpkinMat;

	UPROPERTY(EditInstanceOnly)
	AHazeProp Pumpkin;

	FHazeAcceleratedFloat CurrentLightIntensity;

	UPROPERTY(EditDefaultsOnly)
	const float TimeToReachMaxIntensity = 2;

	UPROPERTY(EditDefaultsOnly)
	const float LitLightIntensity;

	UPROPERTY(EditDefaultsOnly)
	FLinearColor BlueColor;

	UPROPERTY(EditDefaultsOnly)
	FLinearColor YellowColor;


	float UnlitIntensity;

	default InteractComp.MovementSettings.Type = EMoveToType::NoMovement;
	default InteractComp.bShowCancelPrompt = false;
	
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditAnywhere)
	EMoonMarketRevealableColor PlatformType = EMoonMarketRevealableColor::Blue;

	private const float RevealRadius = 1000;
	private float ExtraRevealRadius = 0;
	private const float UnactivatedRevealRadius = 300;
	FHazeAcceleratedFloat CurrentRevealRadius;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		UpdateLanternColor();
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		UnlitIntensity = PointLight.Intensity;
		CurrentLightIntensity.Value = PointLight.Intensity;
		InteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		auto Harp = TListedActors<AMoonGuardianHarp>().Single;
		Harp.OnStartedPlaying.AddUFunction(this, n"ApplyExtraRevealRadius");
		Harp.OnStoppedPlaying.AddUFunction(this, n"ResetExtraRevealRadius");
		UpdateLanternColor();

		DynamicPumpkinMat =  Material::CreateDynamicMaterialInstance(Pumpkin, UHazePropComponent::Get(Pumpkin).GetMaterial(0));
		UHazePropComponent::Get(Pumpkin).SetMaterial(0, DynamicPumpkinMat);
		DefaultEmissiveTint = DynamicPumpkinMat.GetVectorParameterValue(n"EmissiveTint");
		CurrentPumpkinEmissiveTint = DefaultEmissiveTint;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const float TargetIntensity = InteractingPlayer != nullptr ? LitLightIntensity : UnlitIntensity;

		CurrentLightIntensity.AccelerateTo(TargetIntensity, TimeToReachMaxIntensity, DeltaSeconds);
		PointLight.SetIntensity(CurrentLightIntensity.Value);

		float TargetRadius = RevealRadius + ExtraRevealRadius;
		if(InteractingPlayer == nullptr)
			TargetRadius = UnactivatedRevealRadius;
		else if(InteractingPlayer.IsPlayerDead())
			TargetRadius = 0;

		CurrentRevealRadius.AccelerateTo(TargetRadius, TimeToReachMaxIntensity, DeltaSeconds);

		if(Time::GetGameTimeSince(StartInteractionTime) < 2)
		{
			FLinearColor TargetTint = InteractingPlayer != nullptr ? FLinearColor::White : DefaultEmissiveTint;
			CurrentPumpkinEmissiveTint = Math::CInterpTo(CurrentPumpkinEmissiveTint, TargetTint, DeltaSeconds, 1);
			DynamicPumpkinMat.SetVectorParameterValue(n"EmissiveTint", CurrentPumpkinEmissiveTint);
		}
	}
	
	void UpdateLanternColor()
	{
		const bool bIsBlue = PlatformType == EMoonMarketRevealableColor::Blue;
		PointLight.LightColor = bIsBlue ? BlueColor : YellowColor;
	}

	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player) override
	{
		Super::OnInteractionStarted(InteractionComponent, Player);
		UPlayerRespawnComponent::Get(Player).OnPlayerRespawned.AddUFunction(this, n"OnRespawn");

		UMoonMarketLanternInteractionComponent::Get(Player).StartPickingUpLantern(this);
	}

	UFUNCTION()
	private void ApplyExtraRevealRadius(UMoonGuardianHarpPlayingComponent HarpPlayer)
	{
		if(InteractingPlayer != HarpPlayer.OwningPlayer)
			ExtraRevealRadius = 300;
	}


	UFUNCTION()
	private void ResetExtraRevealRadius()
	{
		ExtraRevealRadius = 0;
	}

	void OnInteractionStopped(AHazePlayerCharacter Player) override
	{
		UMoonMarketRevealingLanternEventHandler::Trigger_OnDropped(this);
		UPlayerRespawnComponent::Get(Player).OnPlayerRespawned.Unbind(this, n"OnRespawn");
		DynamicPumpkinMat.SetVectorParameterValue(n"EmissiveTint", DefaultEmissiveTint);
		CurrentPumpkinEmissiveTint = DefaultEmissiveTint;
		UMoonMarketLanternInteractionComponent::Get(Player).Lantern = nullptr;
		
		Super::OnInteractionStopped(Player);
	}

	UFUNCTION()
	private void OnRespawn(AHazePlayerCharacter RespawnedPlayer)
	{
		AttachToComponent(RespawnedPlayer.Mesh, n"MoonMarketLanternSocket", EAttachmentRule::SnapToTarget);
	}
};