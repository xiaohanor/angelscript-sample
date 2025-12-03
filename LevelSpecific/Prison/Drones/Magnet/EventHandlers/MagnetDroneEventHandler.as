struct FMagnetDroneMagneticJumpEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector TargetLocation;
	
	UPROPERTY(BlueprintReadOnly)
	FVector TargetNormal;

	UPROPERTY(BlueprintReadOnly)
	FVector OriginLocation;
}

struct FMagnetDronePreviewAttractionPathEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector StartLocation;
	UPROPERTY(BlueprintReadOnly)
	FVector StartTangent;

	UPROPERTY(BlueprintReadOnly)
	FVector EndLocation;
	UPROPERTY(BlueprintReadOnly)
	FVector EndTangent;

	UPROPERTY(BlueprintReadOnly)
	FHazeRuntimeSpline ImmediateSpline;
};

UCLASS(Abstract)
class UMagnetDroneEventHandler : UHazeEffectEventHandler
{
	UPROPERTY()
	AHazePlayerCharacter Player = nullptr;

	UPROPERTY()
	UMagnetDroneComponent DroneComp = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		DroneComp = UMagnetDroneComponent::Get(Player);
		check(DroneComp != nullptr);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartPreviewAttractionPath(FMagnetDronePreviewAttractionPathEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TickPreviewAttractionPath(FMagnetDronePreviewAttractionPathEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopPreviewAttractionPath() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AttractionStarted(FMagnetDroneAttractionStartedParams AttractionData) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AttractionCanceled() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Attached(FMagnetDroneAttachmentParams AttachmentData) { }

	// When the magnet attachment is canceled
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Detached() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void NoMagneticSurfaceFound() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void JumpStart() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void JumpStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void MagnetDroneDash() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void MagnetDroneBounce() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void MagnetDroneLand() {}

}