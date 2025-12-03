class ASkylineBallBossSmallBossShockwave : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ShockWaveRoot;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY()
	float LifeTime = 5.0;

	UPROPERTY(EditAnywhere)
	float ScaleSpeed = 2.0;

	UPROPERTY()
	float Damgage = 0.4;

	float Radius = 0.0;

	private TPerPlayer<UPlayerMovementComponent> MoveComp;
	private TPerPlayer<ESkylineBossShockwaveGroundState> GroundStateLastFrame;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (auto Player : Game::GetPlayers())
		{
			MoveComp[Player] = UPlayerMovementComponent::Get(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Scale = ScaleSpeed * GetGameTimeSinceCreation();
		Scale = Math::Max(0.1, Scale);
		Radius = Scale * 100.0;
		
		ShockWaveRoot.SetWorldScale3D(FVector(Scale, Scale, 1.0));

		if (GetGameTimeSinceCreation() > LifeTime)
			DestroyActor();

		for (auto Player : Game::GetPlayers())
		{
			if (HasPlayerWalkedOverShockwave(Player))
			{
				FVector DeathDir = (Player.ActorLocation - ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
				Player.DamagePlayerHealth(Damgage, FPlayerDeathDamageParams(DeathDir), DamageEffect, DeathEffect);
			}

			PrintToScreen("" + Player + " is " + GroundStateLastFrame[Player]);

			GroundStateLastFrame[Player] = GetGroundState(Player);
		}	
	}

	ESkylineBossShockwaveGroundState GetGroundState(AHazePlayerCharacter Player) const
	{
		if (!MoveComp[Player].IsOnAnyGround())
			return ESkylineBossShockwaveGroundState::NotGrounded;

		bool bIsInFront = MoveComp[Player].GroundContact.Location.Dist2D(ActorLocation, FVector::UpVector) < Radius;

		if(bIsInFront)
			return ESkylineBossShockwaveGroundState::GroundedInFront;
		else
			return ESkylineBossShockwaveGroundState::GroundedBehind;
	}

	bool HasPlayerWalkedOverShockwave(AHazePlayerCharacter Player) const
	{
		if (GetGroundState(Player) == ESkylineBossShockwaveGroundState::NotGrounded)
			return false;
		
		// If we were grounded last frame...
		bool bGrounded = GroundStateLastFrame[Player] != ESkylineBossShockwaveGroundState::NotGrounded;
		if(bGrounded)
		{
			const ESkylineBossShockwaveGroundState GroundStateThisFrame = GetGroundState(Player);

			// ...and we were behind and now in front, or vice versa, then we have walked across the shockwave
			if(GroundStateLastFrame[Player] != GroundStateThisFrame)
			{
				return true;
			}
		}

		return false;
	}
};