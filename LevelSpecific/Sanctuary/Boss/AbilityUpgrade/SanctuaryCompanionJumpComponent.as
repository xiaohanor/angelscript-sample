event void FActivateSanctuaryWingSuitSignature(AHazePlayerCharacter Player);
event void FDeactivateSanctuaryWingSuitSignature(AHazePlayerCharacter Player);

class USanctuaryCompanionJumpComponent : UActorComponent
{
	UPROPERTY()
	float JumpHeight = 1000.0;

	UPROPERTY()
	float ActivateWingSuitDelay = 0.5;

	UPROPERTY()
	int OrbsRequiredToInfuse = 3;
	int OrbsAquired = 0;

	UPROPERTY()
	FActivateSanctuaryWingSuitSignature OnActivateWingSuit;

	UPROPERTY()
	FDeactivateSanctuaryWingSuitSignature OnDeactivateWingSuit;

	UPROPERTY()
	UNiagaraSystem LightBirdInfusedTrailSystem;
	UNiagaraComponent LightBirdInfusedTrailComp;

	UPROPERTY()
	UNiagaraSystem DarkPortalInfusedTrailSystem;
	UNiagaraComponent DarkPortalInfusedTrailComp;

	UPROPERTY()
	UNiagaraSystem AttackEffect;

	AHazePlayerCharacter Player;

	AHazeCharacter Companion;
	bool bWingSuitActive = false;

	FDarkPortalInvestigationDestination DarkPortalInvestParams;	
	default DarkPortalInvestParams.OverrideSpeed = 10000.0;

	FLightBirdInvestigationDestination LightBirdInvestParams;
	default LightBirdInvestParams.OverrideSpeed = 10000.0;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		DarkPortalInvestParams.TargetComp = Game::Zoe.RootComponent;
		LightBirdInvestParams.TargetComp = Game::Mio.RootComponent;

		if (Player == Game::Zoe)
			Companion = DarkPortalCompanion::GetDarkPortalCompanion();
		else
			Companion = LightBirdCompanion::GetLightBirdCompanion();

		UPlayerHealthComponent::Get(Player).OnStartDying.AddUFunction(this, n"DeactivateWingSuit");
	}

	UFUNCTION()
	private void DeactivateWingSuit()
	{
		if (Player.IsAnyCapabilityActive(n"WingSuit"))
			OnDeactivateWingSuit.Broadcast(Player);
	}

	UFUNCTION()
	void OrbAquired()
	{
		OrbsAquired++;

		Companion.Mesh.SetWorldScale3D(Companion.Mesh.WorldScale + FVector(0.5));
		
		if (OrbsAquired >= OrbsRequiredToInfuse)
		{
			bWingSuitActive = true;
			OrbsAquired = 0;
			OnActivateWingSuit.Broadcast(Cast<AHazePlayerCharacter>(Owner));

			if (Player == Game::Zoe)
			{
				DarkPortalCompanion::DarkPortalInvestigate(DarkPortalInvestParams, this);
				DarkPortalInfusedTrailComp = Niagara::SpawnLoopingNiagaraSystemAttached(DarkPortalInfusedTrailSystem, Companion.Mesh);
			}
			else
			{
				LightBirdCompanion::LightBirdInvestigate(LightBirdInvestParams, this);
				LightBirdInfusedTrailComp = Niagara::SpawnLoopingNiagaraSystemAttached(LightBirdInfusedTrailSystem, Companion.Mesh);
			}
		}
	}

	UFUNCTION()
	void WingSuitDeactivated()
	{
		if (!bWingSuitActive)
			return;

		Companion.Mesh.SetWorldScale3D(FVector(1.0));
		bWingSuitActive = false;

		if (Player == Game::Zoe)
		{
			DarkPortalCompanion::DarkPortalStopInvestigating(this);
			DarkPortalInfusedTrailComp.DestroyComponent(this);
		}
		else
		{
			LightBirdCompanion::LightBirdStopInvestigating(this);
			LightBirdInfusedTrailComp.DestroyComponent(this);
		}
	}
};

UFUNCTION(BlueprintPure)
USanctuaryCompanionJumpComponent GetSanctuaryCompanionJumpComponentMio()
{
	return USanctuaryCompanionJumpComponent::Get(Game::Mio);
}

UFUNCTION(BlueprintPure)
USanctuaryCompanionJumpComponent GetSanctuaryCompanionJumpComponentZoe()
{
	return USanctuaryCompanionJumpComponent::Get(Game::Zoe);
}