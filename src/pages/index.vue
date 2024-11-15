<template>
    <v-container class="pt-lg-15">
        <div class="text-h3 text-center mb-10">The Bid Calculation Tool</div>

        <v-sheet class="mx-auto pa-5" width="400">
            <v-form fast-fail validate-on="submit lazy" @submit.prevent>
                <v-select
                    v-model="selectedType"
                    label="Vehicle Type"
                    :items="vehicleTypes"
                    variant="outlined"
                ></v-select>

                <v-number-input
                    v-model="vehiclePrice"
                    :rules="vehiclePriceRules"
                    :reverse="false"
                    controlVariant="default"
                    label="Vehicle Price"
                    :hideInput="false"
                    inset
                    variant="outlined"
                ></v-number-input>

                <v-card class="elevation-0">
                    <v-list density="compact" disabled>
                        <v-list-item v-for="(fee, i) in fees" :key="i">
                            <v-list-item-title>
                                <strong>{{ fee.text }}:</strong> {{ fee.price }}
                            </v-list-item-title>
                        </v-list-item>
                    </v-list>
                </v-card>

                <v-btn :loading="loading" @click="saveResults(vehiclePrice, selectedType, fees)" class="mt-4" type="submit" variant="outlined" block>Save results</v-btn>
            </v-form>
        </v-sheet>

        <v-snackbar v-model="snackbar" :timeout="timeout" :color="snackbarColor">
            {{ snackbarMessage }}
            <template v-slot:actions>
                <v-btn variant="text" @click="snackbar = false">
                    OK
                </v-btn>
            </template>
        </v-snackbar>
    </v-container>
</template>
<script>
export default {
    data: () => ({
        loading: false,
        selectedType: 'common',
        vehicleTypes: [
            { title: 'Common', value: 'common' },
            { title: 'Luxury', value: 'luxury' },
        ],
        vehiclePrice: 0,
        vehiclePriceRules: [
            value => {
                if (value) return true
                return 'Price must not be empty.';
            },
        ],
        fees: {
            buyer: {text: "Buyer's fee", price: 0},
            seller: {text: "Seller's fee", price: 0},
            association: {text: 'Association fee', price: 0},
            storage: {text: 'Storage fee', price: 100},
            total: {text: 'Total', price: 100}
        },
        snackbar: false,
        snackbarColor: 'danger',
        snackbarMessage: 'There vas an error. Please try again later.',
        timeout: 5000,
    }),
    watch: {
        vehiclePrice(newPrice) {
            this.getFees(newPrice, this.selectedType);
        },
        selectedType(newType) {
            this.getFees(this.vehiclePrice, newType);
        }
    },
    methods: {
        async getFees(price, type) {
            try {
                const response = await fetch("http://localhost/api/calculate-fees/?" + new URLSearchParams({
                    price: price,
                    vehicleType: type,
                }).toString());
                const updatedFees = await response.json();

                // Update fees
                Object.keys(updatedFees).forEach((type) => {
                    this.fees[type].price = updatedFees[type].toFixed(2);
                });
            } catch (error) {
                this.updateSnackbar("red", "Unable to calculate fees. Please try again.")
            }
        },
        async saveResults(price, type, fees) {
            this.loading = true

            if (!this.vehiclePrice) {
                this.loading = false;
                return false;
            }

            const formattedFees = [];
            Object.keys(this.fees).forEach((type) => {
                if (type !== 'total') {
                    formattedFees.push({type: type, amount: this.fees[type].price});
                }
            });

            try {
                await fetch("http://localhost/api/vehicles/", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                        price: price,
                        type: type,
                        soldFor: fees['total'].price,
                        fees: formattedFees
                    }),
                });
                this.loading = false;
                this.updateSnackbar("green", "Results have been saved in the database!")

            } catch (error) {
                this.loading = false;
                this.updateSnackbar("red", "Unable to save. Please try again.")
            }
        },
        updateSnackbar(color, message) {
            this.snackbarColor = color;
            this.snackbarMessage = message;
            this.snackbar = true;
        }
    }
}
</script>
