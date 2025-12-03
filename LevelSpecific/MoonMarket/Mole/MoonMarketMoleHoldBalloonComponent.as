class UMoonMarketMoleHoldBalloonComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	AMoonMarketFollowBalloon Balloon;

	UPROPERTY()
	const float BobHeight = 30;

	UPROPERTY()
	const float BobSpeed = 2;

	UPROPERTY(EditAnywhere)
	FHazePlaySlotAnimationParams FireworkAnim;

	AMoonMarketMole Mole;

	FVector OriginalRelativeLocation;
	FVector OriginalInteractCompRelativeLocation;

	bool bAttachedBalloon = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Balloon.bCanRespawn = false;
		Mole = Cast<AMoonMarketMole>(Owner);
		Mole.CapsuleComp.AttachToComponent(Mole.Mesh, n"Hips");
		OriginalRelativeLocation = Mole.Mesh.RelativeLocation;

		if(HasControl())
			CrumbSetBalloon(Balloon, nullptr);
		
		UPolymorphResponseComponent::Get(Mole).OnPolymorphTriggered.AddUFunction(this, n"OnMorph");
		UPolymorphResponseComponent::Get(Mole).OnUnmorphed.AddUFunction(this, n"OnUnmorph");
		UMoonMarketThunderStruckComponent::Get(Mole).OnStruckByThunder.AddUFunction(this, n"OnThunderStruck");
		UFireworksResponseComponent::Get(Mole).OnFireWorksImpact.AddUFunction(this, n"OnFireworkImpact");
	}

	UFUNCTION()
	private void OnMorph()
	{
		UMoonMarketPolymorphAutoAimComponent::Get(Owner).DetachFromComponent();
		ReleaseBalloon(UPolymorphResponseComponent::Get(Mole).InstigatingPlayer);
	}

	UFUNCTION()
	private void OnUnmorph()
	{
		Mole.PolymorphAimComp.AttachToComponent(Mole.Mesh, n"Hips");
	}

	UFUNCTION()
	private void OnThunderStruck(FMoonMarketThunderStruckData Data)
	{
		ReleaseBalloon(Data.InstigatingPlayer);
	}

	UFUNCTION()
	private void OnFireworkImpact(FMoonMarketFireworkImpactData Data)
	{
		if(Balloon == nullptr)
			Mole.PlaySlotAnimation(FireworkAnim);
		else
			ReleaseBalloon(Data.InstigatingPlayer);
	}

	UFUNCTION()
	private void ReleaseBalloon(AHazePlayerCharacter InstigatingPlayer)
	{
		if(Balloon == nullptr)
			return;
		
		if(Balloon.InteractingPlayer == nullptr)
			Balloon.String.bAttachEnd = false;
		
		Balloon.OnPoppedEvent.Unbind(this, n"ReleaseBalloon");
		Balloon.InteractComp.WidgetVisualOffset = FVector::UpVector * 50;
		Balloon.InteractComp.SetRelativeLocation(OriginalInteractCompRelativeLocation);
		Balloon = nullptr;

		Mole.ReactionParams.InstigatingPlayer = InstigatingPlayer;
		Mole.ReactionParams.ActionTag = MoleReactions::LostBalloon;
		TListedActors<AMoonMarketMoleManager>().Single.OnMoleReaction.Broadcast(Mole.ReactionParams);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetBalloon(AMoonMarketFollowBalloon NewBalloon, AHazePlayerCharacter InstigatingPlayer)
	{
		Balloon = NewBalloon;
		Balloon.String.SetAttachEndToComponent(Mole.Mesh, n"LeftHand");
		Balloon.String.bAttachEnd = true;
		Balloon.String.EndLocation = FVector::ZeroVector;
		Balloon.OnPoppedEvent.AddUFunction(this, n"ReleaseBalloon");
		Balloon.InteractComp.WidgetVisualOffset = FVector::UpVector * 200;
		OriginalInteractCompRelativeLocation = Balloon.InteractComp.RelativeLocation;

		if(InstigatingPlayer != nullptr)
		{
			Mole.ReactionParams.InstigatingPlayer = InstigatingPlayer;
			Mole.ReactionParams.ActionTag = MoleReactions::GivenBalloon;
			TListedActors<AMoonMarketMoleManager>().Single.OnMoleReaction.Broadcast(Mole.ReactionParams);
		}
	}

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	void Tick(float DeltaSeconds)
	{
		if(Balloon != nullptr)
		{
			if(Balloon.InteractingPlayer != nullptr)
			{
				ReleaseBalloon(Balloon.InteractingPlayer);
			}
			else
			{
				if(!bAttachedBalloon)
				{
					Balloon.String.SetAttachEndToComponent(Mole.Mesh, n"LeftHand");
					bAttachedBalloon = true;
				}

				FVector HandLocation = Mole.Mesh.GetSocketLocation(n"LeftHand");
				Balloon.InteractComp.SetWorldLocation(HandLocation - Balloon.InteractComp.WidgetVisualOffset);
			}
		}
	}
};