/**
 * Creates and attaches a static mesh to the player when activated.
 */
class USketchbookBowEquipCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = Sketchbook::Bow::DebugCategory;

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(Sketchbook::Bow::SketchbookBow);

	default CapabilityTags.Add(BlockedWhileIn::Crouch);

	USketchbookBowPlayerComponent BowComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BowComp = USketchbookBowPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BowComp.AimComp.ApplyAiming2DPlaneConstraint(FVector::BackwardVector, this);

		BowComp.BowMeshComponent = UHazeSkeletalMeshComponentBase::Create(Player);
		BowComp.BowMeshComponent.SetSkeletalMeshAsset(BowComp.BowMesh);

		BowComp.BowMeshComponent.AnimationMode = EAnimationMode::AnimationBlueprint;
		BowComp.BowMeshComponent.SetAnimClass(BowComp.AnimBlueprint);
		BowComp.BowMeshComponent.AddTickPrerequisiteComponent(Player.Mesh);

		BowComp.BowMeshComponent.CollisionEnabled = ECollisionEnabled::NoCollision;
		BowComp.BowMeshComponent.SetCollisionProfileName(n"NoCollision");
		BowComp.BowMeshComponent.SetGenerateOverlapEvents(false);
		BowComp.BowMeshComponent.AddTag(ComponentTags::HideOnCameraOverlap);

		BowComp.BowMeshComponent.SetRenderCustomDepth(true);
		BowComp.BowMeshComponent.SetCustomDepthStencilValue(Player.Mesh.CustomDepthStencilValue);

		BowComp.BowMeshComponent.AttachToComponent(Player.Mesh, Sketchbook::Bow::BowAttachSocket);

		// Setup the arrow anim mesh
		BowComp.ArrowAnimMeshComponent = UStaticMeshComponent::Create(Player);
		BowComp.ArrowAnimMeshComponent.SetStaticMesh(BowComp.ArrowMesh);

		BowComp.ArrowAnimMeshComponent.AttachToComponent(BowComp.BowMeshComponent, n"Align");
		BowComp.ArrowAnimMeshComponent.SetRelativeLocation(FVector(40, 0, 0));
		BowComp.ArrowAnimMeshComponent.SetRelativeScale3D(FVector(1.4));

		BowComp.ArrowAnimMeshComponent.SetCollisionProfileName(n"NoCollision");
		BowComp.ArrowAnimMeshComponent.SetGenerateOverlapEvents(false);
		BowComp.ArrowAnimMeshComponent.AddTag(ComponentTags::HideOnCameraOverlap);

		BowComp.ArrowAnimMeshComponent.SetRenderCustomDepth(true);
		BowComp.ArrowAnimMeshComponent.SetCustomDepthStencilValue(Player.Mesh.CustomDepthStencilValue);

		BowComp.ArrowAnimMeshComponent.SetHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BowComp.AimComp.ClearAiming2DConstraint(this);

		BowComp.BowMeshComponent.DestroyComponent(Player);
		BowComp.BowMeshComponent = nullptr;

		BowComp.ArrowAnimMeshComponent.DestroyComponent(Player);
		BowComp.ArrowAnimMeshComponent = nullptr;
	}
}