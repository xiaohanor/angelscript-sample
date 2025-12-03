class AStoneBeastNeckAttachActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Visuals;
	default Visuals.SpriteName = "S_TriggerSphere";
#endif

	UPROPERTY(DefaultComponent)
	UStoneBeastNeckRenderedComponent RenderComp;

	UPROPERTY(EditAnywhere)
	AHazeSkeletalMeshActor DragonSkeletalActor;

	UPROPERTY(EditAnywhere)
	FName BoneName;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AttachToActor(DragonSkeletalActor, BoneName, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Debug::DrawDebugSphere(ActorLocation, 100.0, 12, FLinearColor::Red, 10.0, 0.0, true);
		// Debug::DrawDebugSphere(DragonSkeletalActor.Mesh.GetBoneTransform(BoneName).Location, 50.0, 12, FLinearColor::Green, 10.0, 0.0, true);
	}

	UFUNCTION(CallInEditor)
	void SetToBoneLocation()
	{
		if (DragonSkeletalActor == nullptr)
			return;

		if (BoneName == "")
			return;
		
		FVector DrawLocation = DragonSkeletalActor.Mesh.GetBoneTransform(BoneName).Location;	

		ActorLocation = DrawLocation;
	}
};

class UStoneBeastNeckRenderedComponent : UHazeEditorRenderedComponent
{
	default bIsEditorOnly = true;

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
		AStoneBeastNeckAttachActor NeckAttach = Cast<AStoneBeastNeckAttachActor>(Owner);

		if (NeckAttach == nullptr)
			return;

		SetActorHitProxy();
		SetRenderForeground(true);
		FVector DrawLocation = NeckAttach.DragonSkeletalActor.Mesh.GetBoneTransform(NeckAttach.BoneName).Location;
		DrawWireSphere(DrawLocation, 50.0, FLinearColor::Green, 8.0, 12);
		DrawCircle(DrawLocation, 2000.0, FLinearColor::Green, 15.0, FVector(0,0,1), 20);
	}
}

