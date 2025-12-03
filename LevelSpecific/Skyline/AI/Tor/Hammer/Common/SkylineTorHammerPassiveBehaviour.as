
class USkylineTorHammerPassiveBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UBasicAIHealthComponent HealthComp;
	USkylineTorHammerComponent HammerComp;
	USkylineTorSettings Settings;

	float DirectionTime;
	bool bDirection;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);

		UGravityBladeCombatResponseComponent BladeResponse = UGravityBladeCombatResponseComponent::GetOrCreate(Owner);
		BladeResponse.OnHit.AddUFunction(this, n"OnBladeHit");
	
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
		HammerComp.HoldHammerComp.Hammer.FauxRotateComp.ApplyImpulse(HammerComp.HoldHammerComp.Hammer.HeadLocation.WorldLocation, Force);
	}

	UFUNCTION()
	private void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if(HammerComp.CurrentMode != ESkylineTorHammerMode::MeleeGrounded)
			return;
		Cooldown.Set(0.5);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
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
		UBasicAIMovementSettings::SetTurnDuration(Owner, 2.5, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(Game::Mio);
		DestinationComp.MoveTowards(Owner.ActorLocation + Owner.ActorRightVector * Math::Sin(ActiveDuration) * 100, 150);
	}
}