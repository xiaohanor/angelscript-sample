class APaddleRaftPushingVolumeBox : APaddleRaftPushingVolumeBase
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionProfileName(n"Trigger");
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);
	default BoxComp.bGenerateOverlapEvents = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent ArrowComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		BoxComp.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
		BoxComp.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		ArrowComp.RelativeLocation = FVector(-BoxComp.BoxExtent.X, 0, 0);
	}

	FVector GetForceAtPointInOverlap(FVector WorldLocation) override
	{
		FVector ToPlayer = WorldLocation - ArrowComp.WorldLocation;
		
		float Size = ToPlayer.ProjectOnToNormal(ArrowComp.ForwardVector).Size();
		float Alpha = Math::Saturate(Size / BoxComp.BoxExtent.X);
		FVector Force = ArrowComp.ForwardVector * MaxForceSize * Alpha;
		//Debug::DrawDebugDirectionArrow(ArrowComp.WorldLocation, Force.GetSafeNormal(), Force.Size(), 20, FLinearColor::Red, 10);
		return Force;
	}
}
