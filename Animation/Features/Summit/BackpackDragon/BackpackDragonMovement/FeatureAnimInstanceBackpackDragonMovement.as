UCLASS(Abstract)
class UFeatureAnimInstanceBackpackDragonMovement : UHazeFeatureSubAnimInstance
{
    // The Feature associated with this Feature Sub Anim Instance
    UPROPERTY(Transient, BlueprintHidden, NotEditable)
    ULocomotionFeatureBackpackDragonMovement Feature;

    // Read all Feature Anim Data from this struct in the Anim Graph
    UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FLocomotionFeatureBackpackDragonMovementAnimData AnimData;

    UHazePhysicalAnimationComponent PhysAnimComp;
    UPlayerMovementComponent MoveComp;

    UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    bool bIsMoving;

    UFUNCTION(BlueprintOverride)
    void BlueprintBeginPlay()
    {
    }

    UFUNCTION(BlueprintOverride)
    void BlueprintInitializeAnimation()
    {
        ULocomotionFeatureBackpackDragonMovement NewFeature = GetFeatureAsClass(ULocomotionFeatureBackpackDragonMovement);
        if (Feature != NewFeature)
        {
            Feature = NewFeature;
            AnimData = NewFeature.AnimData;
        }

        if (Feature == nullptr)
            return;

        if (Feature.PhysAnimProfile != nullptr)
        {
            if (PhysAnimComp == nullptr)
                PhysAnimComp = UHazePhysicalAnimationComponent::GetOrCreate(HazeOwningActor);

            PhysAnimComp.ApplyProfileAsset(this, Feature.PhysAnimProfile);
        }

		if(HazeOwningActor.AttachParentActor != nullptr)
        	MoveComp = UPlayerMovementComponent::Get(HazeOwningActor.AttachParentActor);
    }

    /*UFUNCTION(BlueprintOverride)
    float GetBlendTime() const
    {
        return 0.2f;
    }
    */

    UFUNCTION(BlueprintOverride)
    void BlueprintUpdateAnimation(float DeltaTime)
    {
        if (Feature == nullptr)
            return;

        bIsMoving = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero() || !MoveComp.Velocity.IsNearlyZero(50);
    }

    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom() const
    {
        return true;
    }

    UFUNCTION(BlueprintOverride)
    void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
    {
    }
}
