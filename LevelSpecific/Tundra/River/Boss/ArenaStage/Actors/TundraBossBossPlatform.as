class ATundraBossBossPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USphereComponent BlockingCollision;
	default BlockingCollision.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(EditInstanceOnly)
	AHazeActor LaunchTargetActor;

	UPROPERTY(EditInstanceOnly)
	bool bStartHidden = false;

	UPROPERTY(EditInstanceOnly)
	float RootHideOffset = -800;
	
	bool bCurrentlyHidden = false;
	FHazeTimeLike MovePlatformUp;
	default MovePlatformUp.Duration = 0.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovePlatformUp.BindUpdate(this, n"MovePlatformUpUpdate");
		MovePlatformUp.BindFinished(this, n"MovePlatformUpFinished");

		if(bStartHidden)
		{
			MeshRoot.SetRelativeLocation(FVector(0, 0, RootHideOffset));
			bCurrentlyHidden = true;
			DisablePlatform(true);
		}
		else
		{
			BlockingCollision.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
		}
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(bStartHidden)
			MeshRoot.SetRelativeLocation(FVector(0, 0, RootHideOffset));
		else
			MeshRoot.SetRelativeLocation(FVector(0, 0, 0));
	}

	UFUNCTION()
	private void MovePlatformUpUpdate(float CurrentValue)
	{
		float Z_Value = Math::Lerp(RootHideOffset, 0, CurrentValue);
		MeshRoot.SetRelativeLocation(FVector(0, 0, Z_Value));
	}

	UFUNCTION()
	private void MovePlatformUpFinished()
	{
		if(MovePlatformUp.IsReversed())
		{
			DisablePlatform(true);
		}
		else
		{
			BlockingCollision.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
		}
	}

	void ShowPlatform()
	{
		if(!bCurrentlyHidden)
			return;

		LaunchPlayers();
		MovePlatformUp.PlayFromStart();
		BP_StartedMovingUp();
		DisablePlatform(false);
		bCurrentlyHidden = false;
	}

	void HidePlatform()
	{
		if(bCurrentlyHidden)
			return;

		BlockingCollision.CollisionEnabled = ECollisionEnabled::NoCollision;
		MovePlatformUp.ReverseFromEnd();
		BP_StartedMovingDown();
		bCurrentlyHidden = true;
	}

	//If a player is within the area that the platform will emerge from, launch them to the middle of the arena
	void LaunchPlayers()
	{
		for(auto Player : Game::Players)
		{
			if(!Player.HasControl())
				continue;
			
			if (GetHorizontalDistanceTo(Player) < BlockingCollision.SphereRadius)
			{
				FPlayerLaunchToParameters LaunchParams;
				LaunchParams.LaunchToLocation = LaunchTargetActor.ActorLocation;
				LaunchParams.Type = EPlayerLaunchToType::LaunchToPoint;
				LaunchParams.Duration = 2;
				Player.LaunchPlayerTo(this, LaunchParams);		
			}
		}
	}

	void DisablePlatform(bool bShouldBeDisabled)
	{
		SetActorHiddenInGame(bShouldBeDisabled);
		SetActorEnableCollision(!bShouldBeDisabled);
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartedMovingUp()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_StartedMovingDown()
	{}
};