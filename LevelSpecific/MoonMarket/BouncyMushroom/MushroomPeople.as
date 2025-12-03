class AMushroomPeople : AWitchBouncyMushroomActor
{
	default Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = MeshScalerAnimation)
	UCapsuleComponent CapsuleComp;
	default CapsuleComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	UPROPERTY(DefaultComponent, Attach = MeshScalerAnimation)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent)
	UMoonMarketNPCWalkComponent WalkComp;
	default WalkComp.WalkSpeed = 450;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedPositionComp;
	default SyncedPositionComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Character;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UMoonMarketThunderStruckComponent ThunderResponseComp;

	UPROPERTY(DefaultComponent)
	UFireworksResponseComponent FireworkResponseComp;

	UPROPERTY(DefaultComponent)
	UMoonMarketPolymorphAutoAimComponent PolymorphAimComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;

	UPROPERTY(EditInstanceOnly)
	FMoonMarketMushroomPeopleReaction ReactionParams;

	UPROPERTY(EditAnywhere)
	bool bStartScaled;

	UPROPERTY(EditAnywhere)
	float BobPlayRate = 1.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (SkelMesh.AnimationData.AnimToPlay != nullptr)
			SkelMesh.AnimationData.SavedPosition = Math::RandRange(0.0, SkelMesh.AnimationData.AnimToPlay.PlayLength);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		ReactionParams.Mushroom = this;
		ThunderResponseComp.OnStruckByThunder.AddUFunction(this, n"OnThunderStruck");
		FireworkResponseComp.OnFireWorksImpact.AddUFunction(this, n"OnFireworkImpact");

		auto PolymorphComp = UPolymorphResponseComponent::Get(this);
		if(PolymorphComp != nullptr)
		{
			PolymorphComp.OnPolymorphTriggered.AddUFunction(this, n"OnPolymorphTriggered");
			PolymorphComp.OnUnmorphed.AddUFunction(this, n"OnUnmorphed");
		}
		
	}

	UFUNCTION()
	private void OnPolymorphTriggered()
	{
		CapsuleComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	}

	UFUNCTION()
	private void OnUnmorphed()
	{
		CapsuleComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
		CapsuleComp.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);
		CapsuleComp.SetCollisionResponseToChannel(ECollisionChannel::WorldGeometry, ECollisionResponse::ECR_Ignore);
		CapsuleComp.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldStatic, ECollisionResponse::ECR_Ignore);
	}

	UFUNCTION()
	private void OnThunderStruck(FMoonMarketThunderStruckData Data)
	{
		if(ThunderResponseComp.ThunderStruckAnimation.Animation != nullptr)
		{
			ReactionParams.InstigatingPlayer = Data.InstigatingPlayer;
			ReactionParams.ActionTag = MushroomPeopleReactions::BigReaction;
			ReactionParams.Priority = 3;
			TListedActors<AMoonMarketMushroomPeopleManager>().Single.OnMushroomPeopleReaction.Broadcast(ReactionParams);
		}
	}

	UFUNCTION()
	private void OnFireworkImpact(FMoonMarketFireworkImpactData Data)
	{
		if(AttachmentRootActor.IsA(AHazePlayerCharacter))
		{
			Cast<AHazePlayerCharacter>(AttachmentRootActor).KillPlayer();
		}
		else if(ThunderResponseComp.ThunderStruckAnimation.Animation != nullptr)
		{
			UMoonMarketNPCStunComponent::Get(this).StunDuration = 1.5;
			WalkComp.LastStunTime = 1.5;
			ReactionParams.InstigatingPlayer = Data.InstigatingPlayer;
			ReactionParams.ActionTag = MushroomPeopleReactions::BigReaction;
			ReactionParams.Priority = 3;
			TListedActors<AMoonMarketMushroomPeopleManager>().Single.OnMushroomPeopleReaction.Broadcast(ReactionParams);
			SkelMesh.PlaySlotAnimation(ThunderResponseComp.ThunderStruckAnimation);
		}
	}

	void Bounce(AHazePlayerCharacter Player) override
	{
		Super::Bounce(Player);

		ReactionParams.InstigatingPlayer = Player;
		ReactionParams.ActionTag = MushroomPeopleReactions::JumpedOn;
		ReactionParams.Priority = 1;
		TListedActors<AMoonMarketMushroomPeopleManager>().Single.OnMushroomPeopleReaction.Broadcast(ReactionParams);
	}
};