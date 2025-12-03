event void FSkylineGeckoAreaEnterSignature();

class USkylineGeckoAreaPlayerComponent : UActorComponent
{
	FVector UpVector;
	FSkylineGeckoAreaEnterSignature OnEnterArea;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UpVector = GetFixedVector(Cast<AHazeActor>(Owner).GetGravityDirection());
	}

	bool SameArea(AHazeActor Character)
	{
		return UpVector != -FVector::UpVector;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UGravityBladeGrappleUserComponent GrappleComp = UGravityBladeGrappleUserComponent::Get(Owner);
		if(GrappleComp == nullptr)
			return;

		if(GrappleComp.ActiveGrappleData.ShiftComponent == nullptr)
			return;

		FVector NewVector = GetFixedVector(GrappleComp.ActiveGrappleData.ShiftComponent.UpVector*-1);
		if(NewVector != UpVector)
		{				
			UpVector = NewVector;	
			OnEnterArea.Broadcast();
		}			
	}

	private FVector GetFixedVector(FVector Vector)
	{
		FVector Fixed = FVector::ZeroVector;	
		Fixed.X = GetFixedSign(Vector.X);
		Fixed.Y = GetFixedSign(Vector.Y);
		Fixed.Z = GetFixedSign(Vector.Z);
		return Fixed;
	}

	private float GetFixedSign(float Sign)
	{
		if(Math::IsNearlyEqual(Sign, 1))
			return 1;
		if(Math::IsNearlyEqual(Sign, -1))
			return -1;
		return 0;
	}
}