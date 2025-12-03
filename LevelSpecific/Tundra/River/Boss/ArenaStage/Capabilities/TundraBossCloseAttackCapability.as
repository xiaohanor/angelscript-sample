/*



NOT USING THIS ATTACK



*/

class UTundraBossCloseAttackCapability : UTundraBossChildCapability
{
	float Duration;
	TArray<AHazePlayerCharacter> PlayersInCloseActorVolume;
	TArray<ETundraBossStates> BlockedStates;
	float Cooldown = 8;
	float LastTimeThatCapabilityWasActive = -8;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Boss.CloseAttackVolume.OnComponentBeginOverlap.AddUFunction(this, n"HandleBeginOverlap");
		Boss.CloseAttackVolume.OnComponentEndOverlap.AddUFunction(this, n"HandleEndOverlap");
		
		BlockedStates.Add(ETundraBossStates::BreakingIce);
		BlockedStates.Add(ETundraBossStates::SphereDamage);
		BlockedStates.Add(ETundraBossStates::Grabbed);
		BlockedStates.Add(ETundraBossStates::FinalPunch);
		BlockedStates.Add(ETundraBossStates::ChargeAttack);
		BlockedStates.Add(ETundraBossStates::RingsOfIceSpikes);
	}

	UFUNCTION()
	private void HandleBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player != nullptr)
		{
			PlayersInCloseActorVolume.AddUnique(Player);
		}
	}

	UFUNCTION()
	private void HandleEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                              UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player != nullptr)
		{
			PlayersInCloseActorVolume.Remove(Player);
		}
	}

	UFUNCTION()
	bool PlayersOverlappingCloseArea() const
	{
		for(auto Player : PlayersInCloseActorVolume)
		{
			UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player);
			if(!HealthComp.bIsDead)
			{
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(LastTimeThatCapabilityWasActive + Cooldown > Time::GetGameTimeSeconds())
			return false;

		if(!PlayersOverlappingCloseArea())
			return false;

		if(!Boss.CurrentPhaseAttackStruct.bCloseAttackActive)
			return false;

		//Don't let capability activate if the boss currently is in any of the
		//specified "Blocked States". For instance, he should not be able to do
		//the close attack he's in the "grabbed" or the "take damage" states
		//Some of this is already dealt with by ordering in the Compound
		for(auto State : BlockedStates)
		{
			if(Boss.State == State)
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Duration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Duration = Boss.AnimInstance.GetTundraBossAnimationDuration(ETundraBossAttackAnim::CloseAttack);
		Boss.RequestAnimation(ETundraBossAttackAnim::CloseAttack);
		Boss.CloseAttack.AddUFunction(this, n"HandleCloseAttack");
	}

	UFUNCTION()
	private void HandleCloseAttack()
	{
		for(auto Player : PlayersInCloseActorVolume)
		{
			if(Player.HasControl())
			{
				Player.KillPlayer(FPlayerDeathDamageParams(), Boss.CloseAttackDeathEffect);
			}
		}
		
		Boss.CloseAttack.Unbind(this, n"HandleCloseAttack");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.Mesh.SetAnimBoolParam(n"ExitIceKingAnimation", true);
		LastTimeThatCapabilityWasActive = Time::GetGameTimeSeconds();
	}
};