event void FOnBabyTailAttachedTo(FBabyDragonTailClimbFreeFormAttachParams Params);
event void FOnBabyTailReleased(FBabyDragonTailClimbFreeFormReleasedParams Params);
event void FOnBabyTailJumpedFrom(FBabyDragonTailClimbFreeFormJumpedFromParams Params);

struct FBabyDragonTailClimbFreeFormAttachParams
{
	UPROPERTY()
	UPrimitiveComponent AttachComponent;
	UPROPERTY()
	FVector WorldAttachLocation;
	UPROPERTY()
	FVector AttachNormal;
}

struct FBabyDragonTailClimbFreeFormReleasedParams
{
	UPROPERTY()
	UPrimitiveComponent AttachComponent;
	UPROPERTY()
	FVector WorldAttachLocation;
	UPROPERTY()
	FVector AttachNormal;
}

struct FBabyDragonTailClimbFreeFormJumpedFromParams
{
	UPROPERTY()
	UPrimitiveComponent AttachComponent;
	UPROPERTY()
	FVector WorldAttachLocation;
	UPROPERTY()
	FVector AttachNormal;
	UPROPERTY()
	FVector JumpVelocity;
}

class UBabyDragonTailClimbFreeFormResponseComponent : USceneComponent
{
	// If true, this will only trigger events when the parent component is hit
	UPROPERTY(EditAnywhere)
	bool bIsPrimitiveParentExclusive = false;

	UPROPERTY()
	FOnBabyTailAttachedTo OnTailAttached;

	UPROPERTY()
	FOnBabyTailReleased OnTailReleased;

	UPROPERTY()
	FOnBabyTailJumpedFrom OnTailJumpedFrom;

	bool AttachmentWasOnParent(UPrimitiveComponent ComponentAttachedTo) const 
	{
		auto PrimitiveParent = Cast<UPrimitiveComponent>(GetAttachParent());
		if(PrimitiveParent != nullptr && PrimitiveParent == ComponentAttachedTo)
			return true;

		return false;
	}
};