event void FSandHandWeakPointHit(FSandHandHitData HitData);
event void FSandHandWeakPointEventHealthDepleted(USandHandWeakPointStaticMeshComponent WeakPoint, FInstigator Instigator);

class USandHandWeakPointStaticMeshComponent : UStaticMeshComponent
{
	access Internal = private, USandHandWeakPointStaticMeshComponentVisualizer;

	UPROPERTY(EditDefaultsOnly, Category = "Weak Point")
	private int Health = 10;

	UPROPERTY(EditDefaultsOnly, Category = "Auto Aim")
	access:Internal
	FVector AutoAimRelativeLocation = FVector(0, 0, 0);

	UPROPERTY(EditDefaultsOnly, Category = "Auto Aim")
	private float AutoAimMaximumDistance = 50000.0;

	UPROPERTY(EditDefaultsOnly, Category = "Auto Aim")
	private bool bIgnoreThisComponentForAimTrace = true;

	UPROPERTY(EditDefaultsOnly, Category = "Response Component")
	private FVector ResponseCompRelativeLocationOffset = FVector::ZeroVector;

	UPROPERTY(EditDefaultsOnly, Category = "Response Component")
	private FVector ResponseCompBoundsExtentMultiplier = FVector::OneVector;

	UPROPERTY()
	FSandHandWeakPointHit OnHit;

	UPROPERTY()
	FSandHandWeakPointEventHealthDepleted OnHealthDepleted;

	private USandHandAutoAimTargetComponent AutoAimTargetComp;
	private USandHandResponseComponent ResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AutoAimTargetComp = USandHandAutoAimTargetComponent::Create(Owner);
		AutoAimTargetComp.AttachToComponent(this);
		AutoAimTargetComp.SetRelativeLocation(GetAutoAimTargetCompLocation(false));
		AutoAimTargetComp.MaximumDistance = AutoAimMaximumDistance;

		if(bIgnoreThisComponentForAimTrace)
		{
			AutoAimTargetComp.bIgnoreActorCollisionForAimTrace = false;
			AutoAimTargetComp.AddAutoAimTraceIgnoredComponent(this);
		}

		ResponseComp = USandHandResponseComponent::Create(Owner);
		ResponseComp.AttachToComponent(this);
		ResponseComp.SetRelativeLocation(GetResponseCompBoundsCenter(false));
		ResponseComp.CollisionSettings.BoxExtents = GetResponseCompBoundsExtent(true);

		ResponseComp.OnSandHandHitEvent.AddUFunction(this, n"OnSandHandHit");
	}
	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(EndPlayReason == EEndPlayReason::Destroyed)
		{
			AutoAimTargetComp.DestroyComponent(Owner);
			ResponseComp.DestroyComponent(Owner);
		}
	}

	UFUNCTION()
	private void OnSandHandHit(FSandHandHitData HitData)
	{
		HandleDamage(HitData);
	}

	private void HandleDamage(const FSandHandHitData& HitData)
	{
		OnHit.Broadcast(HitData);

		Health -= 1;

		if(Health <= 0)
		{
			OnHealthDepleted.Broadcast(this, HitData.Caster);
			this.DestroyComponent(Owner);
		}
	}

	UFUNCTION(BlueprintPure)
	FVector GetAutoAimTargetCompLocation(bool bWorldSpace = true) const
	{
		if(bWorldSpace)
		{
			return WorldTransform.TransformPosition(AutoAimRelativeLocation);
		}
		else
		{
			return AutoAimRelativeLocation;
		}
	}

	UFUNCTION(BlueprintPure)
	float GetAutoAimMaxDistance() const
	{
		return AutoAimMaximumDistance;
	}

	UFUNCTION(BlueprintPure)
	FVector GetResponseCompBoundsCenter(bool bWorldSpace = true) const
	{
		if(StaticMesh == nullptr)
			return FVector::ZeroVector;

		if(bWorldSpace)
			return WorldTransform.TransformPosition(StaticMesh.BoundingBox.Center + ResponseCompRelativeLocationOffset);
		else
			return (StaticMesh.BoundingBox.Center + ResponseCompRelativeLocationOffset);
	}

	UFUNCTION(BlueprintPure)
	FVector GetResponseCompBoundsExtent(bool bWorldSpace = true) const
	{
		if(StaticMesh == nullptr)
			return FVector::ZeroVector;

		if(bWorldSpace)
			return WorldTransform.Scale3D * (StaticMesh.BoundingBox.Extent * ResponseCompBoundsExtentMultiplier);
		else
			return (StaticMesh.BoundingBox.Extent * ResponseCompBoundsExtentMultiplier);
	}
};

#if EDITOR
class USandHandWeakPointStaticMeshComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USandHandWeakPointStaticMeshComponent;

	bool bAutoAimSelected = false;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		const auto WeakPoint = Cast<USandHandWeakPointStaticMeshComponent>(Component);
		if(WeakPoint == nullptr)
			return;

		if(!Editor::IsPlaying())
		{
			{
				SetRenderForeground(true);

				FVector AutoAimWorldLocation = WeakPoint.GetAutoAimTargetCompLocation(true);
				SetHitProxy(n"AutoAimOffset", EVisualizerCursor::GrabHand);
				//DrawWireSphere(AutoAimWorldLocation, 100, FLinearColor::Blue);

				SetRenderForeground(false);
				
				//DrawWireSphere(AutoAimWorldLocation, WeakPoint.GetAutoAimMaxDistance(), FLinearColor::Red);
			}

			//DrawWireBox(WeakPoint.GetResponseCompBoundsCenter(true), WeakPoint.GetResponseCompBoundsExtent(true), WeakPoint.ComponentQuat, FLinearColor::Yellow);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndEditing()
	{
		bAutoAimSelected = false;
	}

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key, EInputEvent Event)
	{
		if (HitProxy == n"AutoAimOffset")
		{
			bAutoAimSelected = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool GetWidgetLocation(FVector& OutLocation) const
	{
		const auto SelectedWeakPoint = Cast<USandHandWeakPointStaticMeshComponent>(EditingComponent);

		if (bAutoAimSelected)
		{
			OutLocation = SelectedWeakPoint.GetAutoAimTargetCompLocation(true);
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool GetCustomInputCoordinateSystem(EVisualizerCoordinateSystem CoordSystem, EVisualizerWidgetMode WidgetMode, FTransform& OutTransform) const
	{
		if (!bAutoAimSelected)
			return false;

		const auto SelectedWeakPoint = Cast<USandHandWeakPointStaticMeshComponent>(EditingComponent);

		OutTransform = FTransform::MakeFromXZ(SelectedWeakPoint.ForwardVector, SelectedWeakPoint.UpVector);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool HandleInputDelta(FVector& DeltaTranslate, FRotator& DeltaRotate, FVector& DeltaScale)
	{
		if (!bAutoAimSelected)
			return false;

		auto SelectedWeakPoint = Cast<USandHandWeakPointStaticMeshComponent>(EditingComponent);
		if (!DeltaTranslate.IsNearlyZero())
		{
			FVector LocalTranslation = SelectedWeakPoint.WorldTransform.InverseTransformVector(DeltaTranslate);
			SelectedWeakPoint.AutoAimRelativeLocation += LocalTranslation;
		}

		return true;
	}
}
#endif