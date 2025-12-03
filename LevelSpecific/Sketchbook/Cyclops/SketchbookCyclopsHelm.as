class ASketchbookCyclopsHelmet : ASketchbook_BowHit
{
	UPROPERTY(DefaultComponent)
	UBoxComponent Sphere;

	UPROPERTY(DefaultComponent)
	USketchbookArrowResponseComponent ResponseComp;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		TListedActors<ASketchbookCyclopsRiddleManager>().Single.Riddles[0].Answers.Last().Text.OnFinishedBeingDrawn.AddUFunction(this, n"SetCollisionDisabled");
		AttachToComponent(Cast<ASketchbookCyclops>(AttachParentActor).Mesh, n"Head", EAttachmentRule::KeepWorld);
	}

	UFUNCTION()
    void SetCollisionDisabled()
    {
        Sphere.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		Sphere.SetHiddenInGame(true);
    }
};