class AMoonMarketMole : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent CapsuleComp;
	default CapsuleComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
	default CapsuleComp.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = Mesh, AttachSocket = "Head")
	UStaticMeshComponent Hat;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	UPROPERTY(DefaultComponent)
	UMoonMarketPolymorphAutoAimComponent PolymorphAimComp;

	UPROPERTY(DefaultComponent)
	UMoonMarketThunderStruckComponent ThunderStruckComp;

	UPROPERTY(DefaultComponent)
	UMoonMarketBouncyBallResponseComponent CandyResponseComp;

	UPROPERTY(DefaultComponent)
	UMoonMarketTrumpetHonkResponseComponent TrumpetResponseComp;

	UPROPERTY(DefaultComponent)
	UMoonMarketNPCStunComponent StunComponent;

	UPROPERTY(DefaultComponent)
	UFireworksResponseComponent FireworkResponseComp;

	UPROPERTY(DefaultComponent)
	UMoonMarketNPCWalkComponent WalkComp;
	default WalkComp.bActivated = false;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedPositionComp;
	default SyncedPositionComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Character;

	UPROPERTY(EditInstanceOnly)
	FMoonMarketMoleReaction ReactionParams;

	UPolymorphResponseComponent PolymorphComp;

	UPROPERTY(EditInstanceOnly)
	bool bAlwaysTalking = false;

	UPROPERTY(EditInstanceOnly, Category = "Fur Materials")
	UMaterialInterface OverrideGardenMaterial;
	UMaterialInterface OriginalGardenMaterial;
	UPROPERTY(EditInstanceOnly, Category = "Fur Materials")
	UMaterialInterface OverrideFurMaterial;
	UMaterialInterface OriginalFurMaterial;

	UPROPERTY(EditAnywhere)
	UMaterialInterface HatMaterial;

	bool bHasTriggeredConstruction;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (!bHasTriggeredConstruction)
		{
			OriginalFurMaterial = Mesh.GetMaterial(1);
			OriginalGardenMaterial = Mesh.GetMaterial(2);
			bHasTriggeredConstruction = true;
		}

		ReactionParams.Mole = this;

		if (HatMaterial != nullptr)
			Hat.SetMaterial(0, HatMaterial);
		
		if (Mesh.AnimationData.AnimToPlay != nullptr)
			Mesh.AnimationData.SavedPosition = Math::RandRange(0.0, Mesh.AnimationData.AnimToPlay.PlayLength);

		if (OverrideFurMaterial != nullptr)
		{
			Mesh.SetMaterial(1, OverrideFurMaterial);
			Mesh.SetMaterial(2, OverrideGardenMaterial);
		}
		else
		{
			Mesh.SetMaterial(1, OriginalFurMaterial);
			Mesh.SetMaterial(2, OriginalGardenMaterial);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TListedActors<AMoonMarketMoleManager>().Single.OnMolesActivated.AddUFunction(this, n"Activate");
		MoveComp.ApplyResolverExtension(UMoonMarketYarnBallMovementResolverExtension, this);

		ThunderStruckComp.OnStruckByThunder.AddUFunction(this, n"OnThunderStruck");
		ThunderStruckComp.OnRainedOn.AddUFunction(this, n"OnRainedOn");
		CandyResponseComp.OnHitByBallEvent.AddUFunction(this, n"OnHitByCandy");
		FireworkResponseComp.OnFireWorksImpact.AddUFunction(this, n"OnHitByFirework");
		TrumpetResponseComp.OnHonkedAt.AddUFunction(this, n"OnHonkedAt");
		PolymorphComp = UPolymorphResponseComponent::Get(this);
		PolymorphComp.OnPolymorphTriggered.AddUFunction(this, n"OnPolymorphTriggered");
		PolymorphComp.OnUnmorphed.AddUFunction(this, n"OnUnmorphed");

		Mesh.AddTag(n"HideOnCameraOverlap");
		Hat.AddTag(n"HideOnCameraOverlap");
		CapsuleComp.AddTag(n"HideOnCameraOverlap");
	}

	UFUNCTION()
	private void Activate()
	{
		WalkComp.bActivated = true;
	}

	UFUNCTION(BlueprintCallable)
	void ReactionFinished()
	{
		FMoonMarketMoleReactionFinished Params;
		Params.Mole = this;
		TListedActors<AMoonMarketMoleManager>().Single.OnMoleReactionFinished.Broadcast(Params);
	}

	UFUNCTION()
	private void OnThunderStruck(FMoonMarketThunderStruckData Data)
	{
		SetAnimTrigger(n"ThunderStruck");
		ReactionParams.InstigatingPlayer = Data.InstigatingPlayer;
		ReactionParams.ActionTag = MoleReactions::Thunder;
		ReactionParams.Priority = 3;
		TListedActors<AMoonMarketMoleManager>().Single.OnMoleReaction.Broadcast(ReactionParams);
	}

	UFUNCTION()
	private void OnRainedOn(FMoonMarketInteractingPlayerEventParams Data)
	{
		ReactionParams.InstigatingPlayer = Data.InteractingPlayer;
		ReactionParams.ActionTag = MoleReactions::RainReaction;
		ReactionParams.Priority = 1;
		TListedActors<AMoonMarketMoleManager>().Single.OnMoleReaction.Broadcast(ReactionParams);
	}

	UFUNCTION()
	private void OnHitByCandy(FMoonMarketBouncyBallHitData Data)
	{
		SetAnimTrigger(n"CandyHit");
		ReactionParams.InstigatingPlayer = Data.InstigatingPlayer;
		ReactionParams.ActionTag = MoleReactions::Candy;
		ReactionParams.Priority = 2;
		TListedActors<AMoonMarketMoleManager>().Single.OnMoleReaction.Broadcast(ReactionParams);
	}

	UFUNCTION()
	private void OnHitByFirework(FMoonMarketFireworkImpactData Data)
	{
		SetAnimTrigger(n"FireworkHit");
		WalkComp.LastStunTime = 1.5;
		ReactionParams.InstigatingPlayer = Data.InstigatingPlayer;
		ReactionParams.ActionTag = MoleReactions::Firework;
		ReactionParams.Priority = 3;
		TListedActors<AMoonMarketMoleManager>().Single.OnMoleReaction.Broadcast(ReactionParams);
	}

	UFUNCTION()
	private void OnHonkedAt(AHazePlayerCharacter InstigatingPlayer)
	{
		SetAnimTrigger(n"HonkedAt");
		ReactionParams.InstigatingPlayer = InstigatingPlayer;
		ReactionParams.ActionTag = MoleReactions::Trumpet;
		ReactionParams.Priority = 2;
		TListedActors<AMoonMarketMoleManager>().Single.OnMoleReaction.Broadcast(ReactionParams);
	}

	UFUNCTION()
	private void OnPolymorphTriggered()
	{
		CapsuleComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
		ReactionParams.InstigatingPlayer = PolymorphComp.InstigatingPlayer;
		ReactionParams.ActionTag = MoleReactions::Polymorph;
		ReactionParams.Priority = 2;
		TListedActors<AMoonMarketMoleManager>().Single.OnMoleReaction.Broadcast(ReactionParams);
	}

	UFUNCTION()
	private void OnUnmorphed()
	{
		CapsuleComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
		CapsuleComp.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);
		CapsuleComp.SetCollisionResponseToChannel(ECollisionChannel::WorldGeometry, ECollisionResponse::ECR_Ignore);
		CapsuleComp.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldStatic, ECollisionResponse::ECR_Ignore);
		ReactionParams.InstigatingPlayer = PolymorphComp.InstigatingPlayer;
		ReactionParams.ActionTag = MoleReactions::Unmorph;
		ReactionParams.Priority = 2;

		if(TListedActors<AMoonMarketMoleManager>().Single != nullptr)
			TListedActors<AMoonMarketMoleManager>().Single.OnMoleReaction.Broadcast(ReactionParams);
	}
};