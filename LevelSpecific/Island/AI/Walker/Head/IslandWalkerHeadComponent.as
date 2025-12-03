enum EIslandWalkerHeadState
{
	Attached,
	Deployed,
	Detached,
	Swimming,
	Escape,
	Destroyed
}

struct FIslandWalkerNeckCable
{
	UNiagaraComponent Effect;
	FVector LocalOrigin;
	FHazeAcceleratedVector AccHead;
	FHazeAcceleratedVector AccNear;
	FHazeAcceleratedVector AccFar;
	FHazeAcceleratedVector AccNeck;

	bool bReach = false;
	FVector ReachLocation;
	FVector ReachEndControl;
}

enum EWalkerHeadHatchState
{
	Closed,
	Struggling,
	Open,
}

class UIslandWalkerHeadComponent : UActorComponent
{
	UPROPERTY()
	UNiagaraSystem NeckCableFX;

	UPROPERTY()
	TSubclassOf<AIslandGrenadeLock> GrenadeLockClass;

	UPROPERTY()
	TSubclassOf<AIslandWalkerHeadShockwave> ShockWaveClass;
	TArray<AIslandWalkerHeadShockwave> ShockWaves;

	UHazeSkeletalMeshComponentBase Mesh; 

	USceneComponent NeckCableOrigin;
	USceneComponent HeadCableOrigin;
	TArray<FIslandWalkerNeckCable> Cables;

	UPROPERTY(BlueprintReadOnly)
	FVector FireSwoopTargetLoc = FVector(BIG_NUMBER);

	EIslandWalkerHeadState State = EIslandWalkerHeadState::Attached;
	bool bSubmerged = false;
	bool bAtEndOfEscape = false;
	bool bHeadShakeOffPlayers = false;
	bool bHeadEscapeSuccess = false;
	float HeadEscapeStartDistanceAlongSpline = 0.0;
	
	AIslandWalkerHeadCrashSite CrashSite;
	FVector CrashDestination;
	float CrashDuration;

	EWalkerHeadHatchState HeadHatchState = EWalkerHeadHatchState::Closed;
	TArray<FInstigator> HatchOpeners;
	float HatchIntegrity = 1.0;

	bool bFinDeployed = false;

	TInstigated<float> MovementFloor;

	int EscapeHurtIndex = -1;
	TArray<int> EscapeHurtIndices;
	float EscapeHurtReactionStartTime = -BIG_NUMBER;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Mesh = Cast<AHazeCharacter>(Owner).Mesh;
	}

	FTransform GetUnscaledNeckTransform() const
	{
		FTransform Transform = NeckCableOrigin.WorldTransform;
		Transform.Scale3D = FVector::OneVector;
		return Transform;
	}

	UFUNCTION(DevFunction)
	void StruggleWithHatch(FInstigator Instigator)
	{
		HeadHatchState = EWalkerHeadHatchState::Struggling;
	}

	UFUNCTION(DevFunction)
	void OpenHatch(FInstigator Instigator)
	{
		HatchOpeners.AddUnique(Instigator);
		HeadHatchState = EWalkerHeadHatchState::Open;
		if (HatchOpeners.Num() == 1)
			UIslandWalkerHeadEffectHandler::Trigger_OnOpenHeadHatch(Cast<AHazeActor>(Owner));
	}

	UFUNCTION(DevFunction)
	void CloseHatch(FInstigator Instigator)
	{
		if (HatchOpeners.Num() == 0)
		{
			if (HeadHatchState == EWalkerHeadHatchState::Struggling)
				HeadHatchState = EWalkerHeadHatchState::Closed;
			return;
		}

		HatchOpeners.RemoveSingleSwap(Instigator);
		if (HatchOpeners.Num() == 0)
		{
			HeadHatchState = EWalkerHeadHatchState::Closed;
			UIslandWalkerHeadEffectHandler::Trigger_OnCloseHeadHatch(Cast<AHazeActor>(Owner));
		}
	}

	void SpawnShockWaves()
	{
		if (ShockWaves.Num() > 0)
			return;
		for (int i = 0; i < 10; i++)
		{
			AIslandWalkerHeadShockwave ShockWave = SpawnActor(ShockWaveClass, Owner.ActorLocation, Owner.ActorRotation, NAME_None, true, Owner.Level);
			ShockWave.MakeNetworked(this, FName("ShockWave_" + i));
			ShockWave.WalkerHead = Cast<AHazeActor>(Owner);
			FinishSpawningActor(ShockWave);
			ShockWaves.Add(ShockWave);
		}
	}

	void ThrowOffNonInteractingPlayers()
	{
		// Throw off any players on top of head which are not interacting (interacting players are handled by interaction capability)
		UIslandWalkerSettings Settings = UIslandWalkerSettings::GetSettings(Cast<AHazeActor>(Owner));
		FVector TopCenterLoc = Mesh.GetSocketLocation(n"Base") + Owner.ActorForwardVector * 250 + Owner.ActorUpVector * 50.0;
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!Player.HasControl())
				continue;

			if (Player.IsAnyCapabilityActive(n"HatchInteraction"))
				continue; // These will be throw off by capability instead

			if (!Player.ActorLocation.IsWithinDist2D(TopCenterLoc, 300.0))
				continue; // Not near head
			if (Player.ActorLocation.Z < TopCenterLoc.Z)
				continue; // Below head top
			if (Player.ActorLocation.Z > TopCenterLoc.Z + 300)
				continue; // Too high above head top

			// Above head, not interacting: yeet!
			FVector Impulse = FVector(0.0, 0.0, Settings.HeadEscapeThrowOffPlayerImpulse.Z);
			Impulse += Owner.ActorForwardVector * Settings.HeadEscapeThrowOffPlayerImpulse.X;
			float SideSign = (Owner.ActorRightVector.DotProduct(Player.ActorLocation - Owner.ActorLocation) > 0.0) ? 1.0 : -1.0;
			Impulse += Owner.ActorRightVector * SideSign * Settings.HeadEscapeThrowOffPlayerImpulse.Y;
			Player.AddMovementImpulse(Impulse);
		}
	}
};


