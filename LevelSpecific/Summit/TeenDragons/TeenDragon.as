
UCLASS(Abstract, NotPlaceable)
class ATeenDragon : AHazeCharacter
{
	default CapsuleComponent.CapsuleHalfHeight = 88.0;
	default CapsuleComponent.CapsuleRadius = 88.0;
	default CapsuleComponent.CollisionProfileName = n"PlayerCharacter";
	default CapsuleComponent.bGenerateOverlapEvents = false;
	default CapsuleComponent.SetCollisionEnabled(ECollisionEnabled::PhysicsOnly);
	default CapsuleComponent.AdditiveOffsetFromBottom = 1.0;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = "Spine4")
	USceneComponent PlayerAttachComponent;

	private AHazePlayerCharacter Player;

	UPROPERTY(BlueprintReadOnly)
	UHazeAnimLookAtDataAsset AnimLookAtDataAsset;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto LookAtComponent = UHazeAnimPlayerLookAtComponent::GetOrCreate(this);
		LookAtComponent.DefaultLookAtAsset = AnimLookAtDataAsset;

		OnPreSequencerControl.AddUFunction(this, n"OnCutsceneStarted");
		OnPostSequencerControl.AddUFunction(this, n"OnCutsceneStopped");
	}
	
	UPROPERTY(EditAnywhere)
	float WingFlappingStrength = 1.0;

	UFUNCTION()
	private void OnCutsceneStarted(FHazePreSequencerControlParams Params)
	{
		CapsuleComponent.RemoveComponentCollisionBlocker(this);
		Player.CapsuleComponent.ClearCapsuleSizeOverride(this);

		DetachFromActor(EDetachmentRule::KeepWorld);
		Player.Mesh.AttachToComponent(Player.MeshOffsetComponent, AttachmentRule = EAttachmentRule::SnapToTarget);
	}

	UFUNCTION()
	private void OnCutsceneStopped(FHazePostSequencerControlParams Params)
	{
		if (!Player.IsAnyCapabilityActive(n"TeenDragonAttachment"))
			return;

		DetachFromActor();
		AttachToComponent(Player.MeshOffsetComponent
			, NAME_None, EAttachmentRule::SnapToTarget
			, EAttachmentRule::SnapToTarget
			, EAttachmentRule::KeepWorld
			, true);
		
		Player.Mesh.AttachToComponent(PlayerAttachComponent, AttachmentRule = EAttachmentRule::SnapToTarget);
	
		CapsuleComponent.AddComponentCollisionBlocker(this);
		Player.CapsuleComponent.OverrideCapsuleSize(CapsuleComponent.CapsuleRadius, CapsuleComponent.CapsuleHalfHeight, this);
		ActorRelativeLocation = FVector::ZeroVector;
	}

	void SetControllingPlayer(AHazePlayerCharacter Rider)
	{
		Player = Rider;

		auto LookAtComponent = UHazeAnimPlayerLookAtComponent::GetOrCreate(this);
		LookAtComponent.SetPlayer(Rider);
	}

	bool IsAcidDragon() const
	{
		return Player == Game::Mio;
	}

	bool IsTailDragon() const
	{
		return Player == Game::Zoe;
	}

	UFUNCTION()
	void SetCavernChaseHighlights(bool bIsActive)
	{
		UPlayerTeenDragonComponent::Get(Player).SetCavernChaseHighlights(bIsActive);
	}

	UPlayerTeenDragonComponent GetDragonComponent() const property
	{
		return UPlayerTeenDragonComponent::Get(Player);
	}
};

