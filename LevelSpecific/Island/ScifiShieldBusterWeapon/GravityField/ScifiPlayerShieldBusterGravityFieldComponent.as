// Visualizer
// #if EDITOR
// class UScifiPlayerShieldBusterGravityFieldVisualizer : UHazeScriptComponentVisualizer
// {
// 	default VisualizedClass = UScifiPlayerShieldBusterGravityFieldComponent;

//     UFUNCTION(BlueprintOverride)
//     void VisualizeComponent(const UActorComponent Component)
//     {
// 		auto TargetComponent = Cast<UScifiPlayerShieldBusterGravityFieldComponent>(Component);
// 		DrawWireSphere(TargetComponent.TargetLocation, 10, FLinearColor::Red, 0.5, 4, false);
//     }   
// } 
// #endif


event void FOnGravityFieldActivate();
event void FOnGravityFieldDeactivate();

// Gravity Field Component
class UScifiPlayerShieldBusterGravityFieldComponent : USceneComponent
{
	// Events
	FOnGravityFieldActivate OnGravityFieldActivate;
	FOnGravityFieldDeactivate OnGravityFieldDeactivate;

	// Target and Origin location
	FHazeAcceleratedVector SpringVector;
	FVector OriginLocation;
	FVector TargetLocation;
	default PrimaryComponentTick.bStartWithTickEnabled = false;
	private float Volume;
	UPROPERTY(EditInstanceOnly)
	private float RemainActiveDuration = 0.0;
	private float DeactivationTimer = 0.0;
	private bool bTryToDeactivate = false;
	private bool bRaising = false;
	private float RaiseDistance;
	UPROPERTY(EditInstanceOnly)
	private float VolumeMultiplier = 1.0;

	UPROPERTY(EditInstanceOnly, Category = "Widget", Meta = (MakeEditWidget = true))
	FVector WidgetLocation;
	default WidgetLocation.Z = 300.0;

	

	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginLocation = Owner.GetActorLocation();
		TargetLocation = this.GetWorldLocation()+Owner.ActorUpVector*WidgetLocation.Z+Owner.ActorRightVector*WidgetLocation.Y+Owner.ActorForwardVector*WidgetLocation.X;
		RaiseDistance = OriginLocation.Distance(TargetLocation);


		FVector BoundOrigin;
		FVector BoundExtent;

		Owner.GetActorBounds(false, BoundOrigin, BoundExtent, true);

		Volume = (BoundExtent.X/100) * (BoundExtent.Y/100) * (BoundExtent.Z/100);

	}

	UFUNCTION()
	void GravityFiendActivate()
	{
		OnGravityFieldActivate.Broadcast();
		Print("Activated", 2.0, FLinearColor::DPink);
		bTryToDeactivate = false;
		ComponentTickEnabled = true;
		bRaising = true;
	}

	UFUNCTION()
	void TryToDeactivate()
	{
		bTryToDeactivate = true;
		DeactivationTimer = RemainActiveDuration;
		Print("Try to deactivate", 2.0, FLinearColor::DPink);
	}

	UFUNCTION()
	private void GravityFieldDeactivate()
	{
		OnGravityFieldDeactivate.Broadcast();
		Print("Deactivated", 2.0, FLinearColor::DPink);
		bRaising = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Print("Ticking", 0.0, FLinearColor::DPink);
		if(bTryToDeactivate)
		{	
			DeactivationTimer -= DeltaSeconds;
			if(DeactivationTimer < 0)
			{
				bTryToDeactivate = false;
				GravityFieldDeactivate();
			}
		}


		if(bRaising)
		{
			
			SpringVector.SpringTo(TargetLocation-OriginLocation, 3, 1, DeltaSeconds);
			Owner.SetActorLocation(SpringVector.Value+OriginLocation);
		}

		else
		{
			SpringVector.AccelerateTo(FVector(0.0,0.0,0.0), 2, DeltaSeconds);
			Owner.SetActorLocation(SpringVector.Value+OriginLocation);
		}

		if((bRaising && Owner.GetActorLocation().Distance(TargetLocation) < 5.0) || (!bRaising && Owner.GetActorLocation().Distance(OriginLocation) < 5.0))
		{
			if(!bRaising)
			{
				ComponentTickEnabled = false;
			}
		}
	}
}

