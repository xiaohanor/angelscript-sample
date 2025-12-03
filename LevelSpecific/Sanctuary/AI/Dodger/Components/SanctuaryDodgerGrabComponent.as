class USanctuaryDodgerGrabComponent : UActorComponent
{
	AHazeCharacter HazeCharacter;
	USanctuaryDodgerSettings DodgerSettings;
	UBasicAITargetingComponent TargetComp;

	AHazeCharacter GrabbedActor;
	float GrabTime;
	float ReleaseTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeCharacter = Cast<AHazeCharacter>(Owner);
		DodgerSettings = USanctuaryDodgerSettings::GetSettings(HazeCharacter);
		TargetComp = UBasicAITargetingComponent::Get(Owner);

		auto HealthComp = UBasicAIHealthComponent::Get(Owner);
		HealthComp.OnTakeDamage.AddUFunction(this, n"OnDodgerTakeDamage");

		ULightBirdResponseComponent::Get(Owner).OnIlluminated.AddUFunction(this, n"OnLightBirdIlluminated");
		UDarkPortalResponseComponent::Get(Owner).OnGrabbed.AddUFunction(this, n"OnDarkPortalGrabbed");
	}

	UFUNCTION()
	private void OnDarkPortalGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponenet)
	{
		Release();
	}

	UFUNCTION()
	private void OnLightBirdIlluminated()
	{
		Release();
	}

	UFUNCTION()
	private void OnDodgerTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage,
	                          EDamageType DamageType)
	{
		Release();
	}

	bool GetbGrabbing() property
	{
		return GrabbedActor != nullptr;
	}

	bool CanGrab(AHazeActor Target)
	{
		if(bGrabbing)
			return false;

		if(Cast<AHazeCharacter>(Target) == nullptr)
			return false;

		auto Team = HazeTeam::GetTeam(SanctuaryDodgerTags::SanctuaryDodgerTeam);

		// Only allow one dodger at a time to grab
		for(AHazeActor Member: Team.GetMembers())
		{
			if (Member == nullptr)
				continue;
			if(Member == Owner)
				continue;
			auto GrabComp = USanctuaryDodgerGrabComponent::Get(Member);
			if(GrabComp == nullptr)
				continue;
			if(GrabComp.bGrabbing)
				return false;
		}

		// Cooldown on grabbing
		if(Time::GetGameTimeSince(Team.GetLastActionTime(SanctuaryDodgerTags::SanctuaryDodgerGrab)) < DodgerSettings.ChargeGrabGlobalCooldown)
			return false;

		return true;
	}

	void Grab(AHazeActor Target)
	{
		auto Character = Cast<AHazeCharacter>(Target);
		if(Character == nullptr) return;

		GrabbedActor = Character;
		Target.AttachToActor(Owner, SocketName = n"Belly");
		Target.AddActorLocalRotation(FRotator(110,180,0));
		Target.AddActorLocalOffset(FVector(0,0,-70));
		Target.BlockCapabilities(n"Movement", this);
		Target.BlockCapabilities(n"Collision", this);

		HazeCharacter.CapsuleComponent.IgnoreActorWhenMoving(Target, true);
		
		TargetComp.GentlemanComponent.SetInvalidTarget(this);
		TargetComp.SetTarget(nullptr);

		auto PlayerHealthComp = UPlayerHealthComponent::Get(Target);
		if(PlayerHealthComp != nullptr)
			PlayerHealthComp.OnStartDying.AddUFunction(this, n"OnPlayerStartDying");

		GrabTime = Time::GetGameTimeSeconds();

		auto Team = HazeTeam::GetTeam(SanctuaryDodgerTags::SanctuaryDodgerTeam);
		Team.ReportAction(SanctuaryDodgerTags::SanctuaryDodgerGrab);
	}

	UFUNCTION()
	private void OnPlayerStartDying()
	{
		Release();
	}

	void Release()
	{
		if(!bGrabbing)
			return;

		auto PlayerHealthComp = UPlayerHealthComponent::Get(GrabbedActor);
		if(PlayerHealthComp != nullptr)
			PlayerHealthComp.OnStartDying.UnbindObject(this);
		
		GrabbedActor.DetachFromActor();
		GrabbedActor.UnblockCapabilities(n"Movement", this);
		GrabbedActor.UnblockCapabilities(n"Collision", this);

		HazeCharacter.CapsuleComponent.IgnoreActorWhenMoving(GrabbedActor, false);

		auto GentComp = UGentlemanComponent::Get(GrabbedActor);
		if(GentComp != nullptr)
			GentComp.ClearInvalidTarget(this);

		GrabbedActor = nullptr;
		ReleaseTime = Time::GetGameTimeSeconds();
	}
}