class UTiltingWorldResponseComponent : UActorComponent
{
    UPROPERTY(EditAnywhere)
    bool bSetGravityDirOnFauxPhysicsComponents = true;

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if(!HasControl())
            return;
        
        if(bSetGravityDirOnFauxPhysicsComponents)
        {
            const FVector GravityDir = -GetWorldUp();

            TArray<UFauxPhysicsWeightComponent> Weights;
            Owner.GetComponentsByClass(Weights);

            for(auto Weight : Weights)
                Weight.SetGravityDir(GravityDir);
        }
    }

    UFUNCTION(BlueprintPure)
    FRotator GetWorldRotation()
    {
        UTiltingWorldMioComponent TiltMioComp = UTiltingWorldMioComponent::Get(Game::GetMio());

        if(TiltMioComp != nullptr)
        {
            return TiltMioComp.GetSmoothWorldRotation();
        }
        else
        {
            USpinningWorldMioComponent SpinMioComp = USpinningWorldMioComponent::Get(Game::GetMio());
            if(SpinMioComp != nullptr)
                return SpinMioComp.GetSmoothWorldRotation();
        }

        return FRotator::ZeroRotator;
    }

    UFUNCTION(BlueprintPure)
    FVector GetWorldUp()
    {
        UTiltingWorldMioComponent TiltMioComp = UTiltingWorldMioComponent::Get(Game::GetMio());

        if(TiltMioComp != nullptr)
        {
            return TiltMioComp.GetSmoothWorldRotation().UpVector;
        }
        else
        {
            USpinningWorldMioComponent SpinMioComp = USpinningWorldMioComponent::Get(Game::GetMio());
            if(SpinMioComp != nullptr)
                return SpinMioComp.GetSmoothWorldRotation().UpVector;
        }

        return FVector::UpVector;
    }
}