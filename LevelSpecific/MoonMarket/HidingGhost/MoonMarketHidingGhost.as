struct FMoonMarketHidingGhostAnimations
{
	UPROPERTY()
	FHazePlaySequenceData PeekMh;

	UPROPERTY()
	FHazePlaySequenceData StartPeek;

	UPROPERTY()
	FHazePlaySequenceData StartHide;
}

class AMoonMarketHidingGhost : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase Ghost;

	UPROPERTY(DefaultComponent, Attach = Ghost, AttachSocket = "Align")
	UStaticMeshComponent Door;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	UPolymorphResponseComponent PolymorphResponseComp;

	UPROPERTY()
	USkeletalMesh CodyMesh;

	UPROPERTY()
	USkeletalMesh MayMesh;

	UPROPERTY()
	FMoonMarketHidingGhostAnimations CodyAnims;

	UPROPERTY()
	FMoonMarketHidingGhostAnimations MayAnims;

	UPROPERTY(EditAnywhere)
	float ReactRadius = 300;

	bool bIsClosed = false;

	float LastFireworkTime = 0;
	bool bFireworkInRange = false;

	UPROPERTY(BlueprintReadOnly)
	bool bIsCody = true;

	bool bShouldBeCody = true;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PolymorphResponseComp.OnPolymorphTriggered.AddUFunction(this, n"Polymorph");
	}

	UFUNCTION()
	private void Polymorph()
	{
		if(bIsClosed)
			return;

		bShouldBeCody = !bShouldBeCody;
		UMoonMarketPolymorphedOwnerEventHandler::Trigger_OnMorph(this, FMoonMarketPolymorphEventParams(bShouldBeCody ? "Cody" : "May", this));
	}

	void UpdateMesh()
	{
		if(bShouldBeCody == bIsCody)
			return;
		
		bIsCody = bShouldBeCody;

		if(bIsCody)
			Ghost.SetSkeletalMeshAsset(CodyMesh);
		else
			Ghost.SetSkeletalMeshAsset(MayMesh);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Time::GetGameTimeSince(LastFireworkTime) < 1)
		{
			bFireworkInRange = true;
			
			if(!bIsClosed)
			{
				bIsClosed = true;
				UMoonMarketCodyDoorEventHandler::Trigger_OnDoorClosed(this, FMoonMarketCodyEventData(bIsCody));
			}
		}
		else
		{
			bFireworkInRange = false;

			float DistToPlayer = Game::GetDistanceFromLocationToClosestPlayer(ActorLocation);
			float Dot = (ActorLocation - Game::GetClosestPlayer(ActorLocation).ActorLocation).GetSafeNormal().DotProduct(ActorForwardVector);

			if(((DistToPlayer <= ReactRadius) && Dot < 0.5) != bIsClosed)
			{
				bIsClosed = !bIsClosed;

				if(bIsClosed)
				{
					UMoonMarketCodyDoorEventHandler::Trigger_OnDoorClosed(this, FMoonMarketCodyEventData(bIsCody));
				}
				else
				{
					UMoonMarketCodyDoorEventHandler::Trigger_OnDoorOpened(this, FMoonMarketCodyEventData(bIsCody));
				}
			}
		}
	}
};