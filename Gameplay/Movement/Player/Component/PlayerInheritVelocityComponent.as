UCLASS(HideCategories = " Debug Activation Cooking Tags Collision")
class UPlayerInheritVelocityComponent : UActorComponent
{
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_DuringPhysics;
	default PrimaryComponentTick.bStartWithTickEnabled = true;

	//Inherited velocity as a scalar 0 - 1
	UPROPERTY(EditInstanceOnly, Category = "VelocityInheritance", meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	private float EndImpactHorizontalVelocityInheritance = 1.0;

	UPROPERTY(EditInstanceOnly, Category = "VelocityInheritance", meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	private float EndImpactVerticalVelocityInheritance = 1.0;

	UPROPERTY(EditInstanceOnly, Category = "VelocityInheritance", meta = (EditCondition = "EndImpactVerticalVelocityInheritance > 0"))
	private bool bOnlyInheritUpwardsVelocity = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PrintWarning(f"UPlayerInheritVelocityComponent is deprecated! Please replace with a UInheritVelocityComponent on {Owner}!");
	}

	void AddFollowAdjustedVelocity(UPlayerMovementComponent MoveComp, FVector& HorizontalVelocity, FVector& VerticalVelocity)
	{
		HorizontalVelocity += MoveComp.GetFollowVelocity().ConstrainToPlane(MoveComp.WorldUp) * EndImpactHorizontalVelocityInheritance;

		if(bOnlyInheritUpwardsVelocity)
		{
			FVector VerticalFollowVelocity = MoveComp.GetFollowVelocity() * EndImpactVerticalVelocityInheritance;
			float FollowVelocityDot = MoveComp.WorldUp.DotProduct(VerticalFollowVelocity);
			
			if(FollowVelocityDot > 0)
				VerticalVelocity += VerticalFollowVelocity;					
		}
		else
			VerticalVelocity += MoveComp.GetFollowVelocity().ConstrainToPlane(MoveComp.Player.ActorForwardVector) * EndImpactVerticalVelocityInheritance;	
	}
}