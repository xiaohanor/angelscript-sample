class USketchbookBossGroundPenetrateCapability : USketchbookCrabBossChildCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction); 

	FVector LastLocation;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		LastLocation = Owner.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(CrabComp.SubPhase != ESketchbookCrabBossSubPhase::Jump && CrabComp.SubPhase != ESketchbookCrabBossSubPhase::Bury)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(CrabComp.SubPhase != ESketchbookCrabBossSubPhase::Jump && CrabComp.SubPhase != ESketchbookCrabBossSubPhase::Bury)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float FloorZ = Boss.ArenaFloorZ;

		FVector GroundLocation = Owner.ActorLocation;
		GroundLocation.Z = FloorZ;

		if(LastLocation.Z < FloorZ && Owner.ActorLocation.Z >= FloorZ)
		{
			Niagara::SpawnOneShotNiagaraSystemAtLocation(CrabComp.JumpOutEffect, GroundLocation);
			for(auto Player : Game::GetPlayers())
			{
				Player.PlayCameraShake(CrabComp.JumpOutCameraShake, this);
				Player.PlayForceFeedback(CrabComp.JumpOutForceFeedback, false, false, this);
			}
		}
		else if(LastLocation.Z >= FloorZ && Owner.ActorLocation.Z < FloorZ && CrabComp.SubPhase == ESketchbookCrabBossSubPhase::Bury)
		{
			Niagara::SpawnOneShotNiagaraSystemAtLocation(CrabComp.BuryEffect, GroundLocation);
			for(auto Player : Game::GetPlayers())
			{
				Player.PlayCameraShake(CrabComp.JumpOutCameraShake, this, 0.5);
				Player.PlayForceFeedback(CrabComp.JumpOutForceFeedback, false, false, this, 0.5);
			}
		}

		LastLocation = Owner.ActorLocation;
	}
};