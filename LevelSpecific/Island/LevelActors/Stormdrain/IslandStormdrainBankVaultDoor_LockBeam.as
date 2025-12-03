enum EIslandBankVaultDoorState
{
	Locked,
	Shootable,
	Unlocked
};

event void FIslandBankVaultBeamUnlocked(AIslandStormdrainBankVaultDoor_LockBeam Beam);
event void FIslandBankVaultBeamLocked(AIslandStormdrainBankVaultDoor_LockBeam Beam);
event void FIslandBankVaultStateChangeSignature();
event void FIslandBankVaultLockBeam_OnShot(float Progress);

class AIslandStormdrainBankVaultDoor_LockBeam : AHazeActor
{
	//default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY()
	FIslandBankVaultStateChangeSignature LockedDelegate;

	UPROPERTY()
	FIslandBankVaultStateChangeSignature UnlockedDelegate;

	UPROPERTY()
	FIslandBankVaultStateChangeSignature ShootableDelegate;

	UPROPERTY()
	FIslandBankVaultLockBeam_OnShot LockShotDelegate();

	UPROPERTY()
	FIslandBankVaultBeamUnlocked BeamUnlockedDelegate;

	UPROPERTY()
	FIslandBankVaultBeamLocked BeamLockedDelegate;

	UPROPERTY(DefaultComponent)
	USceneComponent RootComponent;

	UPROPERTY(DefaultComponent, Attach = "RootComponent")
	USceneComponent Lock;

	UPROPERTY(DefaultComponent, Attach = "Lock")
	USceneComponent RotationScene;

	UPROPERTY(DefaultComponent, Attach = "RotationScene")
	UStaticMeshComponent ShootMesh;

	UPROPERTY(DefaultComponent, Attach = "ShootMesh")
	UIslandRedBlueImpactCounterResponseComponent ImpactComponent;
	default ImpactComponent.bIsPrimitiveParentExclusive = true;

	UPROPERTY()
	EIslandBankVaultDoorState State;

	UPROPERTY(EditInstanceOnly)
	EHazeSelectPlayer UsableByPlayer = EHazeSelectPlayer::Both;

	UPROPERTY(EditInstanceOnly)
	float ActiveForDuration = 5.0;
	float ActiveTimer = 0;
	AIslandStormdrainBankVaultDoor_LockBeam PreviousLock;

	UPROPERTY(EditInstanceOnly)
	bool bActiveFromStart;

	UPROPERTY(EditInstanceOnly)
	AIslandStormdrainBankVaultDoor_LockBeam ActivatesLock;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactComponent.OnImpactEvent.AddUFunction(this, n"OnLockShot");
		ImpactComponent.OnFullAlpha.AddUFunction(this, n"OnLockDestroyed");
		if(bActiveFromStart)
		{
			LockBeam();
			MakeShootable(this);
		}

		else
		{
			LockBeam();
		}
	}

	UFUNCTION()
	void OnLockShot(FIslandRedBlueImpactResponseParams Data)
	{
		float Progress = ImpactComponent.GetImpactAlpha(Game::GetMio()) + ImpactComponent.GetImpactAlpha(Game::GetZoe());
		LockShotDelegate.Broadcast(Progress);
	}

	UFUNCTION()
	void OnLockDestroyed(AHazePlayerCharacter Player)
	{
		if(ActivatesLock != nullptr)
		{
			ActivatesLock.MakeShootable(this);
		}
		UnlockBeam();
	}

	UFUNCTION()
	private void MakeShootable(AIslandStormdrainBankVaultDoor_LockBeam InPreviousLock)
	{
		if(!bActiveFromStart)
		{
			PreviousLock = InPreviousLock;
			ActiveTimer = ActiveForDuration;
			SetActorTickEnabled(true);
		}
		State = EIslandBankVaultDoorState::Shootable;

		for (auto Player : Game::GetPlayersSelectedBy(UsableByPlayer))
		{
			ImpactComponent.UnblockImpactForPlayer(Player, this);
		}

		ShootableDelegate.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(State == EIslandBankVaultDoorState::Shootable && !bActiveFromStart)
		{
			ActiveTimer -= DeltaSeconds;

			if(ActiveTimer <= 0)
			{
				Reset();
			}
		}

		for (auto Player : Game::GetPlayersSelectedBy(UsableByPlayer))
		{
			//PrintToScreen(f"{}"+this.GetName()+" Alpha: "+ImpactComponent.GetImpactAlpha(Player), 0, FLinearColor::Red);
		}
		
	}	

	UFUNCTION()
	void Reset()
	{
		if(!bActiveFromStart)
		{
			LockBeam();
			if(PreviousLock != nullptr)
			{
				PreviousLock.Reset();
			}
		}

		else
		{
			LockBeam();
			MakeShootable(this);
		}
	}

	UFUNCTION()
	private void UnlockBeam()
	{
		//SetActorTickEnabled(false);
		State = EIslandBankVaultDoorState::Unlocked;
		
		ImpactComponent.BlockImpactForPlayer(Game::GetMio(), this);
		ImpactComponent.BlockImpactForPlayer(Game::GetZoe(), this);

		UnlockedDelegate.Broadcast();
		BeamUnlockedDelegate.Broadcast(this);
	}

	UFUNCTION()
	private void LockBeam()
	{
		//SetActorTickEnabled(false);
		State = EIslandBankVaultDoorState::Locked;
		
		ImpactComponent.BlockImpactForPlayer(Game::GetMio(), this);
		ImpactComponent.BlockImpactForPlayer(Game::GetZoe(), this);

		LockedDelegate.Broadcast();
		BeamLockedDelegate.Broadcast(this);
	}
}