class UCentipedeDraggableChainComponent : UCentipedeBiteResponseComponent
{
	UPROPERTY()
	FVector RetractingForce;

	private bool bIsDragged = false;
	private bool bIsRetracting = false;
	bool bIsCapped = false;
	bool bIsHookable = false;
	bool bDidTheImpulse = false;
	UPROPERTY(BlueprintReadOnly)
	float DraggedAlpha = 0.0;
	float ChainsDiffLength = 0.0;

	FVector OriginalLocation;

	private bool bWasHookable = false;
	bool bImpossible = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		OnCentipedeBiteStarted.AddUFunction(this, n"HandleBiteStarted");
		OnCentipedeBiteStopped.AddUFunction(this, n"HandleBiteStopped");
		OriginalLocation = WorldLocation;
	}

	UFUNCTION()
	private void HandleBiteStarted(FCentipedeBiteEventParams BiteParams)
	{
		bBitten = true;
		UPlayerCentipedeDraggableChainComponent::GetOrCreate(BiteParams.Player).DraggableChainComp = this;
	}

	UFUNCTION()
	private void HandleBiteStopped(FCentipedeBiteEventParams BiteParams)
	{
		bBitten = false;
		bIsDragged = false;
		UPlayerCentipedeDraggableChainComponent::GetOrCreate(BiteParams.Player).DraggableChainComp = nullptr;
	}

	void SetIsDragged(bool IsDragged)
	{
		bIsDragged = IsDragged;
		bDidTheImpulse = false;
	}

	bool GetIsDragged() const
	{
		return bIsDragged;
	}

	void ControlApplyRetractingForce(AHazeActor Instigator, float DeltaSeconds)
	{
		if (!devEnsure(Instigator.HasControl(), "Only allowed on control side! What are you doing? talk with ylva"))
			return;
		InternalApplyRetraceForce(DeltaSeconds);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		if (!bBitten)
			InternalApplyRetraceForce(DeltaSeconds);
	}

	private void InternalApplyRetraceForce(float DeltaSeconds)
	{
		if (!bIsHookable && bWasHookable != bIsHookable && !bDidTheImpulse)
		{
			bDidTheImpulse = true;
			FauxPhysics::ApplyFauxImpulseToParentsAt(this, WorldLocation, WorldTransform.TransformVector(-RetractingForce * 0.5));
		}
		FauxPhysics::ApplyFauxForceToParentsAt(this, WorldLocation, WorldTransform.TransformVector(RetractingForce));
		bWasHookable = bIsHookable;
	}
};