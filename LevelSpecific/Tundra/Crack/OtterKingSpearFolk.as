enum ELegToAttachTo
{
	LeftFront,
	RightFront,
	LeftMiddle,
	RightMiddle
};

class AOtterKingSpearFolk : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent OtterMesh;

	UPROPERTY(DefaultComponent)
	UCableComponent CableComp;

	UPROPERTY(DefaultComponent)
	USceneComponent CableEndLocation;

	ATundraWalkingStick Spider;

	FVector CableTargetLocation = FVector::ZeroVector;

	FName Socketname;

	private bool bHasReachedEnd = false;

	UPROPERTY(EditAnywhere)
	ELegToAttachTo LegToAttachTo;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintCallable)
	void ThrowSpear(ATundraWalkingStick SpiderRef)
	{
		Spider = SpiderRef;

		switch (LegToAttachTo)
		{
			case ELegToAttachTo::LeftFront:
				Socketname = n"LeftFrontFoot";
			break;
			case ELegToAttachTo::LeftMiddle:
				Socketname = n"LeftFrontMiddleFoot";
			break;
			case ELegToAttachTo::RightFront:
				Socketname = n"RightFrontFoot";
			break;
			case ELegToAttachTo::RightMiddle:
				Socketname = n"RightFrontMiddleFoot";
			break;
		}

		UOtterKingSpearFolkEffectHandler::Trigger_OnThrowRope(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Spider != nullptr)
		{
			CableTargetLocation = Spider.Mesh.GetSocketLocation(Socketname);
			
			FVector NewCableEndLocation;
			NewCableEndLocation = Math::VInterpConstantTo(CableEndLocation.WorldLocation, CableTargetLocation, DeltaSeconds, 17000);
			CableEndLocation.SetWorldLocation(NewCableEndLocation);

			if(!bHasReachedEnd && NewCableEndLocation.Equals(CableTargetLocation))
			{
				bHasReachedEnd = true;
				UOtterKingSpearFolkEffectHandler::Trigger_OnRopeAttach(this);
			}
		}
	}
};

class UOtterKingSpearFolkEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void OnThrowRope() {}

	UFUNCTION(BlueprintEvent)
	void OnRopeAttach() {}
}