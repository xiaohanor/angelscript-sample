class UPickupComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	FPickupSettings PickupSettings;

	UPROPERTY(EditAnywhere)
	FTransform PlayerCarryOffset;

	UInteractionComponent PickupInteractionComponent = nullptr;

	private FName AttachBone = NAME_None;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AttachBone = GetAttachBoneForType();

		TArray<UInteractionComponent> Interactions;
		Owner.GetComponentsByClass(Interactions);

		for (UInteractionComponent Interaction : Interactions)
		{
			if (Interaction.InteractionSheet == Pickup::PickupInteractionSheet)
			{
				HookUpWithInteractionComponent(Interaction);
				break;
			}
		}
	}

	private void HookUpWithInteractionComponent(UInteractionComponent InteractionComponent)
	{
		if (InteractionComponent == nullptr || PickupInteractionComponent != nullptr)
			return;

		PickupInteractionComponent = InteractionComponent;

		PickupInteractionComponent.MovementSettings.Type = EMoveToType::NoMovement;
		PickupInteractionComponent.bPlayerCanCancelInteraction = false;

		// Setup interaciton condition
		FInteractionCondition InteractionCondition;
		InteractionCondition.BindUFunction(this, n"CanPlayerPickUp");
		PickupInteractionComponent.AddInteractionCondition(this, InteractionCondition);
	}

	UFUNCTION(NotBlueprintCallable)
	private EInteractionConditionResult CanPlayerPickUp(const UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		UPlayerPickupComponent PlayerPickupComponent = UPlayerPickupComponent::Get(Player);
		if (PlayerPickupComponent == nullptr)
			return EInteractionConditionResult::Disabled;

		if (!PlayerPickupComponent.CanPlayerPickUp(this))
			return EInteractionConditionResult::Disabled;

		if (Owner.AttachParentActor != nullptr)
		{
			UPutdownInteractionComponent PutdownInteractionComponent = UPutdownInteractionComponent::Get(Owner.AttachParentActor);
			if (PutdownInteractionComponent != nullptr)
			{
				if (!PutdownInteractionComponent.CanPlayerPickUpFromSocket())
					return EInteractionConditionResult::Disabled;
			}
		}

		return EInteractionConditionResult::Enabled;
	}

	FName GetAttachBone()
	{
		return AttachBone;
	}

	private FName GetAttachBoneForType()
	{
		switch (PickupSettings.PickupType)
		{
			case EPickupType::Light:	return n"Backpack";
			case EPickupType::Heavy:	return n"YoMamma";
		}
	}
}

namespace Pickup
{
	asset PickupInteractionSheet of UHazeCapabilitySheet
	{
		AddCapability(n"PickupInteractionCapability");
	};
};


#if EDITOR
class UPickupComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPickupComponent;

	UPROPERTY(Transient)
	UHazeSkeletalMeshComponentBase PreviewPlayerMeshComponent = nullptr;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		UPickupComponent PickupComponent = Cast<UPickupComponent>(Component);
		if (PickupComponent == nullptr)
			return;

		UMeshComponent Mesh = UMeshComponent::Get(Component.Owner);
		if (Mesh == nullptr)
			return;

		UMaterialInterface MeshShiftPreviewMaterial = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Engine/EngineDebugMaterials/M_SimpleTranslucent.M_SimpleTranslucent"));
		USkeletalMesh PlayerMesh = Cast<USkeletalMesh>(Editor::LoadAsset(n"/Game/Characters/Mio/Mio.Mio"));

		// if (PreviewPlayerMeshComponent == nullptr)
		// {
		// 	PreviewPlayerMeshComponent = UHazeSkeletalMeshComponentBase::GetOrCreate(Component.Owner, n"PreviewPlayerMesh");
		// 	PreviewPlayerMeshComponent.SetSkeletalMesh(PlayerMesh);
		// 	PreviewPlayerMeshComponent.SetMaterial(0, MeshShiftPreviewMaterial);
		// }

		// PreviewPlayerMeshComponent.SetActive(true);
		// PreviewPlayerMeshComponent.SetVisibility(true);

		// PreviewPlayerMeshComponent.SetWorldLocation(Component.Owner.ActorLocation);

		// OOOOR Add function to draw skeletal mesh
		// DrawMesh(PlayerMesh, PickupComponent.Owner.ActorLocation, PickupComponent.Owner.ActorRotation, PickupComponent.Owner.ActorScale3D);
	}

	// UFUNCTION(BlueprintOverride)
	// void EndEditing()
	// {
	// 	PreviewPlayerMeshComponent.SetActive(false);
	// 	PreviewPlayerMeshComponent.SetVisibility(false);
	// }
}
#endif