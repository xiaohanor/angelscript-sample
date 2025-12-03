class ASketchbookCyclopsEye : ASketchbook_BowHit
{
    UPROPERTY(DefaultComponent)
    UStaticMeshComponent Collision;
    
    UPROPERTY(DefaultComponent)
    USketchbookArrowResponseComponent ArrowResponseComp;
    default ArrowResponseComp.bHitAnywhere = true;

    UPROPERTY(DefaultComponent)
    USketchbookBowAutoAimComponent AutoAimComp;

    float TargetEyeScale;
    float EyeScale;

    FVector OriginalPupilRelativeLocation;
    FHazeAcceleratedVector PupilLocation;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Collision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		TListedActors<ASketchbookCyclopsRiddleManager>().Single.Riddles[0].Answers.Last().Text.OnFinishedBeingDrawn.AddUFunction(this, n"SetCollisionEnabled");
        ArrowResponseComp.OnHitByArrow.AddUFunction(this, n"OnHitByArrow");
		AttachToComponent(Cast<ASketchbookCyclops>(AttachParentActor).Mesh, n"Head", EAttachmentRule::KeepWorld);
    }

    UFUNCTION()
    private void OnHitByArrow(FSketchbookArrowHitEventData ArrowHitData, FVector ArrowLocation)
    {
        Sketchbook::GetRiddleManager().OnCyclopsShot();
        AddActorCollisionBlock(this);
    }

	UFUNCTION()
    void SetCollisionEnabled()
    {
        Collision.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
    }
};