struct FSummitExplodyFruitAttachedActivationParams
{
	USummitExplodyFruitTreeAttachment Attachment;
	bool bIsInitialFruit = false;
}

struct FSummitExplodyFruitAttachedDeactivationParams
{
	bool bDetachedNaturally = false;
}

class USummitExplodyFruitAttachedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::BeforeMovement;

	ASummitExplodyFruit Fruit;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Fruit = Cast<ASummitExplodyFruit>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSummitExplodyFruitAttachedActivationParams& Params) const
	{
		if(!Fruit.bIsEnabled)
			return false;

		if(!Fruit.CurrentAttachment.IsSet())
			return false;

		Params.Attachment = Fruit.CurrentAttachment.Value;
		Params.bIsInitialFruit = Fruit.bIsInitialFruit;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSummitExplodyFruitAttachedDeactivationParams& Params) const
	{
		if(!Fruit.bIsEnabled)
		{
			Params.bDetachedNaturally = false;
			return true;
		}

		if(!Fruit.CurrentAttachment.IsSet())
		{
			Params.bDetachedNaturally = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSummitExplodyFruitAttachedActivationParams Params)
	{
		Fruit.ActorLocation = Params.Attachment.WorldLocation - Fruit.TopScaleRoot.RelativeLocation;
		Fruit.ActorRotation = Params.Attachment.WorldRotation;
		Fruit.AttachToComponent(Params.Attachment, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, true);
		Fruit.bIsAttached = true;

		if(!Params.bIsInitialFruit)
			Fruit.TopScaleRoot.WorldScale3D = FVector(0.0001, 0.0001, 0.0001);

		Fruit.bIsAttached = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSummitExplodyFruitAttachedDeactivationParams Params)
	{
		Fruit.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		if(Params.bDetachedNaturally)
		{
			FSummitExplodyFruitFallingFromTreeParams EffectParams;
			EffectParams.FruitStemLocation = Fruit.TopScaleRoot.WorldLocation;
			USummitExplodyFruitTreeEffectHandler::Trigger_OnFruitFallingFromTree(Fruit, EffectParams);
		}
	
		Fruit.bIsAttached = false;
	}
};