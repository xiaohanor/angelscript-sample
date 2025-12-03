
class USkylineTorHammerSmashLandBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UBasicAIHealthComponent HealthComp;
	USkylineTorHammerComponent HammerComp;
	USkylineTorHammerPivotComponent PivotComp;
	USkylineTorHammerSmashComponent SmashComp;
	USkylineTorPhaseComponent TorPhaseComp;
	UGravityWhipResponseComponent WhipResponse;
	USkylineTorHammerGrabMashComponent GrabMashComp;
	USkylineTorHammerStealComponent StealComp;
	USkylineTorHammerVolleyComponent VolleyComp;
	USkylineTorHammerPlayerCollisionComponent PlayerCollisionComp;
	USkylineTorSettings Settings;

	FHazeAcceleratedRotator AccRotation;
	FRotator TargetRotation;

	float ShockwaveTime;
	float ShockwaveInterval = 4;

	int ShockwaveSetNum;
	int GroundedShockwaveSetMax = 0;
	int HoveringShockwaveSetMax = 1;
	float ShockwaveSetTime;
	float ShockwaveSetInterval = 1.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		PivotComp = USkylineTorHammerPivotComponent::GetOrCreate(Owner);
		SmashComp = USkylineTorHammerSmashComponent::GetOrCreate(Owner);
		TorPhaseComp = USkylineTorPhaseComponent::GetOrCreate(HammerComp.HoldHammerComp.Owner);
		GrabMashComp = USkylineTorHammerGrabMashComponent::GetOrCreate(Owner);
		StealComp = USkylineTorHammerStealComponent::GetOrCreate(Owner);
		VolleyComp = USkylineTorHammerVolleyComponent::GetOrCreate(Owner);
		PlayerCollisionComp = USkylineTorHammerPlayerCollisionComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);

		WhipResponse = UGravityWhipResponseComponent::GetOrCreate(Owner);
		WhipResponse.OnGrabbed.AddUFunction(this, n"OnGrabbed");
	}

	UFUNCTION()
	private void OnGrabbed(UGravityWhipUserComponent UserComponent,
	                       UGravityWhipTargetComponent TargetComponent,
	                       TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		USkylineTorHammerEventHandler::Trigger_OnLandStop(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (HammerComp.HoldHammerComp == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		PivotComp.SetPivot(SmashComp.ImpactLocation);
		AccRotation.SnapTo(PivotComp.Pivot.ActorRotation);
		TargetRotation = PivotComp.Pivot.ActorRotation;
		TargetRotation.Pitch = 0;
		InitialHit();
		SmashComp.bLanded = true;
		USkylineTorHammerEventHandler::Trigger_OnLandStart(Owner);

		if(HammerComp.HoldHammerComp.Tor.PhaseComp.Phase == ESkylineTorPhase::Entry)
			return;

		ShockwaveTime = Time::GameTimeSeconds;
		SpawnShockwave(SmashComp.AttackNum);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		SmashComp.bLanded = false;
		PivotComp.RemovePivot();
		USkylineTorHammerEventHandler::Trigger_OnLandStop(Owner);

		if(SmashComp.AttackNum < 2)
			HammerComp.SetMode(ESkylineTorHammerMode::Return);
			

		UHazeCrumbSyncedActorPositionComponent NetworkMotionComp = UHazeCrumbSyncedActorPositionComponent::Get(Owner);
		if (NetworkMotionComp != nullptr)
			NetworkMotionComp.TransitionSync(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccRotation.SpringTo(TargetRotation, 500, 0.2, DeltaTime);
		PivotComp.Pivot.ActorRotation = AccRotation.Value;

		if(StealComp.bEnabled && StealComp.IsStealingExpired())
		{
			DeactivateBehaviour();
		}
		else 
		{
			if(ActiveDuration > 0.25)
				DeactivateBehaviour();
		}	
	}

	void InitialHit()
	{
		float Range = 250;

		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(Player.GetDistanceTo(PivotComp.Pivot) > Range)
				continue;

			UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(Player);
			if (PlayerHealthComp != nullptr)
				PlayerHealthComp.DamagePlayer(HammerComp.HoldHammerComp.Hammer.ProjectileComp.Damage, HammerComp.DamageEffect, HammerComp.DeathEffect);

			FStumble Stumble;
			FVector Dir = (Player.ActorLocation - Owner.ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector);
			Stumble.Move = Dir * 250;
			Stumble.Duration = 0.25;
			Player.ApplyStumble(Stumble);
		}
	}

	private void SpawnShockwave(int Attack)
	{
		ASkylineTorSmashShockwave Shockwave = SpawnActor(SmashComp.ShockwaveClass, SmashComp.ImpactLocation + Owner.ActorUpVector * Settings.SmashDamageWidth / 2, bDeferredSpawn = true, Level = Owner.Level);
		Shockwave.Owner = Owner;
		Shockwave.MaxSpeed = Settings.SmashExpansionBaseSpeed + Settings.SmashExpansionIncrementalSpeed * Attack;
		Shockwave.Duration = 10 - Attack * 2.5;
		Shockwave.Type = ESkylineTorSmashShockwaveType::Wave;
		Shockwave.WaveHeight = 150;
		FinishSpawningActor(Shockwave);
	}
}