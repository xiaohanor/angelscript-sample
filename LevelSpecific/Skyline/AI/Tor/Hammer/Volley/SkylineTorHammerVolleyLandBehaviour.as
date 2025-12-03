
class USkylineTorHammerVolleyLandBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UBasicAIHealthComponent HealthComp;
	USkylineTorHammerComponent HammerComp;
	USkylineTorHammerPivotComponent PivotComp;
	USkylineTorHammerVolleyComponent VolleyComp;
	USkylineTorPhaseComponent TorPhaseComp;
	UGravityWhipResponseComponent WhipResponse;
	UGravityBladeCombatTargetComponent BladeTargetComp;
	UGravityBladeGrappleComponent GrappleComp;
	USkylineTorHammerStealComponent StealComp;
	USkylineTorHammerPlayerCollisionComponent PlayerCollisionComp;
	USkylineTorSettings Settings;

	FHazeAcceleratedRotator AccRotation;
	FRotator TargetRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		PivotComp = USkylineTorHammerPivotComponent::GetOrCreate(Owner);
		VolleyComp = USkylineTorHammerVolleyComponent::GetOrCreate(Owner);
		TorPhaseComp = USkylineTorPhaseComponent::GetOrCreate(HammerComp.HoldHammerComp.Owner);
		BladeTargetComp = UGravityBladeCombatTargetComponent::GetOrCreate(Owner);
		GrappleComp = UGravityBladeGrappleComponent::GetOrCreate(Owner);
		StealComp = USkylineTorHammerStealComponent::GetOrCreate(Owner);
		PlayerCollisionComp = USkylineTorHammerPlayerCollisionComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);

		WhipResponse = UGravityWhipResponseComponent::GetOrCreate(Owner);
		WhipResponse.OnGrabbed.AddUFunction(this, n"OnGrabbed");

		auto MusicManager = UHazeAudioMusicManager::Get();
		if(MusicManager != nullptr)
		{
			MusicManager.OnMainMusicBeat().AddUFunction(this, n"OnMusicBeat");
		}
	}

	UFUNCTION()
	private void OnMusicBeat()
	{
		if(!IsActive())
			return;
		FVector Force = Owner.ActorRightVector * 250;
		HammerComp.HoldHammerComp.Hammer.InvertedFauxRotateComp.ApplyImpulse(Owner.ActorLocation, Force);
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
		if(TorPhaseComp.Phase == ESkylineTorPhase::Entry)
			return false;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		PivotComp.SetPivot(HammerComp.HoldHammerComp.Hammer.TopLocation.WorldLocation);
		AccRotation.SnapTo(PivotComp.Pivot.ActorRotation);
		TargetRotation = PivotComp.Pivot.ActorRotation;
		TargetRotation.Pitch = 0;
		InitialHit();
		VolleyComp.bLanded = true;
		USkylineTorHammerEventHandler::Trigger_OnLandStart(Owner);

		if(HammerComp.HoldHammerComp.Tor.PhaseComp.Phase == ESkylineTorPhase::Entry)
			return;

		ASkylineTorSmashShockwave Shockwave = VolleyComp.SpawnShockwave(ESkylineTorSmashShockwaveType::Wave);

		if(TorPhaseComp.Phase == ESkylineTorPhase::Hovering)
			Shockwave.WaveHeight = 500;
		else
			Shockwave.WaveHeight = 200;

		bool bFirstPhase = HammerComp.HoldHammerComp.Tor.PhaseComp.Phase == ESkylineTorPhase::Grounded && HammerComp.HoldHammerComp.Tor.PhaseComp.SubPhase == ESkylineTorSubPhase::None;
		VolleyComp.bEnableShockwaves = !bFirstPhase;

		if(TorPhaseComp.Phase == ESkylineTorPhase::Hovering)
			DeactivateBehaviour();
		else
			StealComp.EnableStealing(FInstigator(n"HammerVolleyInstigator"), 6, 3, 0.2);

		PlayerCollisionComp.EnableCollision();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		VolleyComp.bLanded = false;
		PivotComp.RemovePivot();
		USkylineTorHammerEventHandler::Trigger_OnLandStop(Owner);
		StealComp.DisableStealing(FInstigator(n"HammerVolleyInstigator"));
		VolleyComp.bEnableShockwaves = false;
		PlayerCollisionComp.DisableCollision();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccRotation.SpringTo(TargetRotation, 500, 0.2, DeltaTime);
		PivotComp.Pivot.ActorRotation = AccRotation.Value;

		if(StealComp.bEnabled && StealComp.IsStealingExpired())
			HammerComp.Recall();
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
				PlayerHealthComp.DamagePlayer(0.5, HammerComp.DamageEffect, HammerComp.DeathEffect);

			FStumble Stumble;
			FVector Dir = (Player.ActorLocation - Owner.ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector);
			Stumble.Move = Dir * 250;
			Stumble.Duration = 0.25;
			Player.ApplyStumble(Stumble);
		}
	}	
}