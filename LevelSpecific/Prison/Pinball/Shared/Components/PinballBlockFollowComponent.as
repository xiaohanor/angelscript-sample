UCLASS(NotBlueprintable)
class UPinballBlockFollowComponent : UActorComponent
{
	TInstigated<bool> bIsBlockingFollow;
	default bIsBlockingFollow.DefaultValue = true;

	private TArray<UPrimitiveComponent> Primitives;
	private bool bHasAppliedBlock = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Owner.GetComponentsByClass(Primitives);
		UpdateIsBlockingFollow();	
	}

	void ApplyBlockFollow(bool bBlockFollow, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		bIsBlockingFollow.Apply(bBlockFollow, Instigator, Priority);
		UpdateIsBlockingFollow();
	}

	void ClearBlockFollow(FInstigator Instigator)
	{
		bIsBlockingFollow.Clear(Instigator);
		UpdateIsBlockingFollow();
	}

	private void UpdateIsBlockingFollow()
	{
		if(bHasAppliedBlock == bIsBlockingFollow.Get())
			return;

		if(bIsBlockingFollow.Get())
		{
			for(auto Primitive : Primitives)
			{
				Primitive.RemoveTag(ComponentTags::InheritHorizontalMovementIfGround);
				Primitive.RemoveTag(ComponentTags::InheritVerticalUpMovementIfGround);
				Primitive.RemoveTag(ComponentTags::InheritVerticalDownMovementIfGround);
			}

			bHasAppliedBlock = true;
		}
		else
		{
			for(auto Primitive : Primitives)
			{
				Primitive.AddTag(ComponentTags::InheritHorizontalMovementIfGround);
				Primitive.AddTag(ComponentTags::InheritVerticalUpMovementIfGround);
				Primitive.AddTag(ComponentTags::InheritVerticalDownMovementIfGround);
			}

			bHasAppliedBlock = false;
		}
	}
};