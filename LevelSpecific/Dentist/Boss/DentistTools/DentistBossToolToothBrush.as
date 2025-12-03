class ADentistBossToolToothBrush : ADentistBossTool
{
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BrushMesh;

	UPROPERTY(DefaultComponent)
	USceneComponent BrushEffectRoot;

	UPROPERTY(DefaultComponent)
	USceneComponent TraceRoot;

	UPROPERTY(DefaultComponent)
	USceneComponent HandAttachRoot;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	FDentistToothApplyRagdollSettings RagdollSettings;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformTemporalLogComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
	default ListedActorComp.bDelistWhileActorDisabled = false;

	UDentistBossTargetComponent TargetComp;

	UDentistBossSettings Settings;

	const float LaunchCooldown = 2.0;

	TPerPlayer<float> TimeLastLaunched;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		AddActorDisable(Dentist);

		TargetComp = UDentistBossTargetComponent::Get(Dentist);
		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	void LaunchPlayer(AHazePlayerCharacter Player)
	{
		if(Time::GetGameTimeSince(TimeLastLaunched[Player]) < LaunchCooldown)
			return;

		FVector DeltaToPlayer = Player.ActorLocation - ActorCenterLocation;
		DeltaToPlayer = DeltaToPlayer.ConstrainToPlane(FVector::UpVector);
		FVector DirToPlayer = DeltaToPlayer.GetSafeNormal();
	
		FVector Impulse = DirToPlayer * Settings.ToothBrushHorizontalImpulseSize + FVector::UpVector * Settings.ToothBrushVerticalImpulseSize; 

		auto ResponseComp = UDentistToothImpulseResponseComponent::Get(Player);
		ResponseComp.OnImpulseFromObstacle.Broadcast(this, Impulse, RagdollSettings);

		TimeLastLaunched[Player] = Time::GameTimeSeconds;

		if(TargetComp.DrillTargets.Contains(Player))
			TargetComp.DrillTargets.RemoveSingleSwap(Player);

		TEMPORAL_LOG(this)
			.DirectionalArrow("Impulse", ActorCenterLocation, Impulse, 20, 40, FLinearColor::Purple)
		;

		FDentistBossEffectHandlerOnToothBrushHitPlayerParams EventParams;
		EventParams.Player = Player;
		UDentistBossEffectHandler::Trigger_OnToothBrushHitPlayer(Dentist, EventParams);
	}

	void Activate() override
	{
		Super::Activate();
		
		RemoveActorDisable(Dentist);
	}

	void Deactivate() override
	{
		Super::Deactivate();
		
		AddActorDisable(Dentist);
	}
};