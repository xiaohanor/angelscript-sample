event void ESummitChainLinkOnMelted(ASummitChainLink Link);

class ASummitChainLink : ANightQueenMetal
{
	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	float LinkLength = 200.0;

	bool bIsLocked = false;
	bool bRotationIsLocked = false;
	bool bIsMelted = false;

	FVector PreviousLocation;
	FVector Velocity;
	FVector StartUp;
	FVector StartRight;
	FVector DesiredLocation;

	ASummitChainLink NextLink;
	ASummitChainLink PreviousLink;

	ESummitChainLinkOnMelted OnLinkMelted;

	USummitChainLinkSpeedAudioComponent AudioComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		// Unused components, which cost to move
		NiagaraComp.DetachFromParent();
		BlockingVolume.DetachFromParent();
		MeshComp.AttachToComponent(RootComponent, AttachmentRule = EAttachmentRule::KeepWorld);
		MeshRoot.DetachFromComponent();

		PreviousLocation = ActorLocation;

		AutoAimComp.TargetShape.SphereRadius = AutoAimComp.TargetShape.SphereRadius * ActorScale3D.X;

		OnNightQueenMetalMelted.AddUFunction(this, n"OnMelted");

		MeshComp.RemoveTag(n"Walkable");
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugLine(ActorLocation + ActorForwardVector * LinkLength * 0.5, ActorLocation - ActorForwardVector * LinkLength * 0.5, FLinearColor::Red, 10);	
	}
#endif

	UFUNCTION()
	private void OnMelted()
	{
		bIsMelted = true;
		OnLinkMelted.Broadcast(this);
	}

	UFUNCTION()
	private void NextLinkWasMelted()
	{
		NextLink = nullptr;
	}

	UFUNCTION()
	private void PreviousLinkWasMelted()
	{
		PreviousLink = nullptr;
	}
};