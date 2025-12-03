
#if EDITOR
class UScifiShieldBusterEnergyWallVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UScifiShieldBusterEnergyWallTargetableComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        auto TargetComponent = Cast<UScifiShieldBusterEnergyWallTargetableComponent>(Component);
		
		// happens on teardown on the dummy component
		if(TargetComponent == nullptr)
			return;
		
		auto Wall = Cast<AScifiShieldBusterEnergyWall>(TargetComponent.GetOwner());
        if (Wall == nullptr)
            return;

		UScifiShieldBusterEnergyWallCutterSettings Settings = Wall.CutterSettings;
		FRotator Rotation =  FRotator::MakeFromXZ(FVector::UpVector, Wall.ActorForwardVector);
		DrawWireCapsule(TargetComponent.GetCutLocation(), Rotation, FLinearColor::LucBlue, Settings.MaxSize, Settings.MovementCollisionIgnoreSize, NumSides = 16);
    }   
} 
#endif