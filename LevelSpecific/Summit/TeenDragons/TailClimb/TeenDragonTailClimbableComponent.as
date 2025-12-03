event void FOnTailClimbStarted(FTeenDragonTailClimbParams Params);
event void FOnTailClimbStopped(FTeenDragonTailClimbParams Params);

class UTeenDragonTailClimbableComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	bool bIsPrimitiveParentExclusive = false;

	UPROPERTY()
	FOnTailClimbStarted OnTailClimbStarted;

	UPROPERTY()
	FOnTailClimbStopped OnTailClimbStopped;

	// Will take the components forward as the preferred direction to start the climb, if you hit areas with different normals, the climb wont start
	UPROPERTY(EditAnywhere)
	bool bUsePreferredClimbStartDirection = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bIsPrimitiveParentExclusive)
		{
			auto PrimitiveParent = Cast<UPrimitiveComponent>(GetAttachParent());
			devCheck(PrimitiveParent != nullptr, f"{this} on {Owner} is set to 'bIsPrimitiveParentExclusive' but its parent component is not a primitive");
		}
	}

	bool ClimbDirectionIsAllowed(FVector Normal)
	{
		if(!bUsePreferredClimbStartDirection)
			return true;

		float AllowedClimbDirectionDotNormal = Normal.DotProduct(ForwardVector);
		if(AllowedClimbDirectionDotNormal > 0.5)
			return true;

		return false;
	}

	void ClimbStarted(FTeenDragonTailClimbParams Params)
	{
		OnTailClimbStarted.Broadcast(Params);
	}

	void ClimbStopped(FTeenDragonTailClimbParams Params)
	{
		OnTailClimbStopped.Broadcast(Params);
	}

	bool ImpactOnParentValid(UPrimitiveComponent ComponentHit) const 
	{
		auto PrimitiveParent = Cast<UPrimitiveComponent>(GetAttachParent());
		if(PrimitiveParent != nullptr && PrimitiveParent == ComponentHit)
			return true;

		return false;
	}
};

#if EDITOR
class UTeenDragonTailClimbableComponentVisualiser : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTeenDragonTailClimbableComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		UTeenDragonTailClimbableComponent Comp = Cast<UTeenDragonTailClimbableComponent>(Component);

		if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
            return;
		
		if(!Comp.bUsePreferredClimbStartDirection)
			return;
		SetRenderForeground(false);

		DrawArrow(Comp.WorldLocation, Comp.WorldLocation + Comp.ForwardVector * 500, FLinearColor::Red, 40,20);
	}
}
#endif