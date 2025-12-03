/**
 * Special Disable Component for the PrisonerTransport actor.
 * Disables collision, and prisoners meshes, but does not disable the actor.
 */
class UPrisonerTransportDisableComponent : UDisableComponent
{
	TArray<UPrimitiveComponent> CollisionMeshes;
	TArray<UHazeSkeletalMeshComponentBase> PrisonerMeshes;

	UPROPERTY(EditDefaultsOnly)
	FName DontBlockCollisionTag = n"DontBlockCollision";

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Owner.GetComponentsByClass(CollisionMeshes);
		Owner.GetComponentsByClass(PrisonerMeshes);

		for(int i = CollisionMeshes.Num() - 1; i >= 0; i--)
		{
			if(CollisionMeshes[i].HasTag(DontBlockCollisionTag))
			{
				CollisionMeshes.RemoveAtSwap(i);
				continue;
			}

			if(!CollisionMeshes[i].IsCollisionEnabled())
			{
				CollisionMeshes.RemoveAtSwap(i);
				continue;
			}
		}

		Super::BeginPlay();
	}

	protected void AddAutoDisableOwner() override
	{
		for(auto CollisionMesh : CollisionMeshes)
		{
			CollisionMesh.AddComponentCollisionBlocker(this);
		}

		for(auto PrisonerMesh : PrisonerMeshes)
		{
			PrisonerMesh.AddComponentTickBlocker(this);
			PrisonerMesh.AddComponentVisualsBlocker(this);
		}
	}

	protected void RemoveAutoDisableOwner() override
	{
		for(auto CollisionMesh : CollisionMeshes)
		{
			CollisionMesh.RemoveComponentCollisionBlocker(this);
		}

		for(auto PrisonerMesh : PrisonerMeshes)
		{
			PrisonerMesh.RemoveComponentTickBlocker(this);
			PrisonerMesh.RemoveComponentVisualsBlocker(this);
		}
	}
};