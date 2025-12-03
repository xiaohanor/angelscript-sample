event void FPickupPlacedInSocketEvent(UPickupComponent Pickup);

class UPutdownInteractionComponent : UInteractionComponent
{
	default InteractionSheet = Pickup::PutdownInteractionSheet;
	default MovementSettings.Type = EMoveToType::NoMovement;
	default bPlayerCanCancelInteraction = false;
	default SetbAbsoluteScale(true);

	// Provides access to putdown interaction capabilities
	access PutdownInteractionCapability = private, UPutdownInteractionCapability;

	access : PutdownInteractionCapability
	UPickupComponent PickupInSocket;

	UPROPERTY(EditAnywhere)
	private EPickupTypeCompatibility PickupCompatibility = EPickupTypeCompatibility::Both;

	UPROPERTY(EditAnywhere)
	private bool bPlayerCanPickupFromSocket = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Meta = (MakeEditWidget))
	FTransform PickupSocketTransform;


#if EDITOR
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Debug")
	UStaticMesh PreviewMesh;
#endif


	UPROPERTY()
	FPickupPlacedInSocketEvent OnPickupPlacedInSocketEvent;

	// Eman TODO: Add putdown settings property including animation and shiet

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		FInteractionCondition InteractionCondition;
		InteractionCondition.BindUFunction(this, n"CanPlayerInteract");
		AddInteractionCondition(this, InteractionCondition);
	}

	UFUNCTION()
	private EInteractionConditionResult CanPlayerInteract(const UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		UPlayerPickupComponent PlayerPickupComponent = UPlayerPickupComponent::Get(Player);
		if (PlayerPickupComponent == nullptr)
			return EInteractionConditionResult::Disabled;

		UPickupComponent Pickup = PlayerPickupComponent.GetCurrentPickup();
		if (Pickup == nullptr)
			return EInteractionConditionResult::Disabled;

		if (!IsPickupCompatibleWithSocket(Pickup))
			return EInteractionConditionResult::Disabled;

		// Eman TODO: Check if player can put down this one thing in a specific place

		return EInteractionConditionResult::Enabled;
	}

	bool CanPlayerPickUpFromSocket()
	{
		return bPlayerCanPickupFromSocket;
	}

	FTransform GetWorldPickupSocketTransform()
	{
		return PickupSocketTransform * Owner.ActorTransform;
	}

	bool IsPickupCompatibleWithSocket(UPickupComponent Pickup)
	{
		if (PickupCompatibility == EPickupTypeCompatibility::Both)
			return true;

		if (Pickup.PickupSettings.PickupType == EPickupType::Light && PickupCompatibility == EPickupTypeCompatibility::Light)
			return true;

		if (Pickup.PickupSettings.PickupType == EPickupType::Heavy && PickupCompatibility == EPickupTypeCompatibility::Heavy)
			return true;

		return false;
	}
}

namespace Pickup
{
	asset PutdownInteractionSheet of UHazeCapabilitySheet
	{
		AddCapability(n"PutdownInteractionCapability");
	};
};